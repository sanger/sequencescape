# A TagSubstitution may be used to replace tags in the event of
# accidental mistagging.
# Currently it supports:
# - Libraries created through the library manifest
# - Libraries created through the old-school tube pipelines
#
# Usage:
# TagSubstitution.new(see_initialize_documentations).save
# Returns false if things failed
class TagSubstitution
  include ActiveModel::Model

  # Named arguments:
  # substitutions: Provide an array of hashes describing your desired substitutions
  #   {
  #     sample_id: The id of the sample to change,
  #     libary_id: The corresponding library id,
  #     original_tag_id: The original tag id, [Required if substitute_tag_id supplied]
  #     substitute_tag_id: the replacement tag id, [Optional]
  #     original_tag2_id: The original tag2 id, [Required if original_tag2_id supplied]
  #     substitute_tag2_id: The replacement tag2 id [Optional]
  #   }
  # user: the user performing the substitution [optional]
  # ticket: support ticket number [optional]
  # comment: any additional comment [optional]

  validates_presence_of :substitutions
  validate :substitutions_valid?, if: :substitutions

  def substitutions_valid?
    @substitutions.reduce(true) do |valid, sub|
      next valid if sub.valid?
      errors.add(:substitution, sub.errors.full_messages)
      valid && false
    end
  end

  class Substitution
    include ActiveModel::Model

    attr_accessor :sample_id, :library_id, :original_tag_id, :substitute_tag_id, :original_tag2_id, :substitute_tag2_id

    delegate :friendly_name, to: :sample, prefix: true

    validates_presence_of :sample_id, :library_id
    validates_presence_of :original_tag_id, if: :substitute_tag_id
    validates_presence_of :original_tag2_id, if: :substitute_tag2_id
    validates_presence_of :matching_aliquots, message: 'could not be found'

    def initialize(attributes)
      super(attributes.extract!(:sample_id, :library_id, :original_tag_id, :substitute_tag_id, :original_tag2_id, :substitute_tag2_id, :aliquot))
      @other_attributes = attributes
    end

    # Used when seeding from a template asset
    # Lets us populate web forms
    def aliquot=(aliquot)
      @sample_id = aliquot.sample_id
      @sample = aliquot.sample
      @library_id = aliquot.library_id
      @original_tag_id = aliquot.tag_id
      @substitute_tag_id = aliquot.tag_id
      @original_tag2_id = aliquot.tag2_id
      @substitute_tag2_id = aliquot.tag2_id
    end

    def sample
      @sample ||= Sample.find(@sample_id)
    end

    def matching_aliquots
      @matching_aliquots ||= find_matching_aliquots
    end

    # Nullify tags sets all tags to null. We need to do this first
    # as otherwise we introduce tag clashes while performing substitutions
    def nullify_tags
      tags_hash = {}
      tags_hash[:tag_id]  = nil if substitute_tag?
      tags_hash[:tag2_id] = nil if substitute_tag2?
      # We DO NOT want to trigger validations here
      Aliquot.where(id: matching_aliquots).update_all(tags_hash) if tags_hash.present? # rubocop:disable Rails/SkipsModelValidations
    end

    def substitute_tags
      Aliquot.where(id: matching_aliquots).find_each do |aliquot|
        aliquot.tag_id = substitute_tag_id if substitute_tag?
        aliquot.tag2_id = substitute_tag2_id if substitute_tag2?
        aliquot.update_attributes(@other_attributes) if @other_attributes.present?
        aliquot.save!
      end
    end

    def comment(oligo_index)
      comment = +"Sample #{sample_id}:"
      comment << " Tag changed from #{oligo_index[original_tag_id]} to #{oligo_index[substitute_tag_id]};" if substitute_tag?
      comment << " Tag2 changed from #{oligo_index[original_tag2_id]} to #{oligo_index[substitute_tag2_id]};" if substitute_tag2?
      @other_attributes.each do |k, v|
        " #{k} changed to #{v};"
      end
      comment
    end

    def tag_ids
      [original_tag_id, substitute_tag_id, original_tag2_id, substitute_tag2_id].compact
    end

    private

    def substitute_tag?
      original_tag_id && original_tag_id != substitute_tag_id
    end

    def substitute_tag2?
      original_tag2_id && original_tag2_id != substitute_tag2_id
    end

    def find_matching_aliquots
      attributes = { sample_id: sample_id, library_id: library_id }
      attributes[:tag_id] = original_tag_id if original_tag_id
      attributes[:tag2_id] = original_tag2_id if original_tag2_id
      Aliquot.where(attributes).pluck(:id)
    end
  end

  attr_accessor :user, :ticket, :comment
  attr_reader :substitutions

  def substitutions=(substitutions)
    @substitutions = substitutions.map { |attrs| Substitution.new(attrs) }
  end

  def save
    return false unless valid?
    # First set all tags to null to avoid the issue of tag clashes
    ActiveRecord::Base.transaction do
      @substitutions.each(&:nullify_tags)
      @substitutions.each(&:substitute_tags)
      rebroadcast_lanes
      apply_comments
    end
    true
  end

  #
  # Provide an asset to build a tag substitution form
  # Will auto populate the fields on substitutions
  # @param asset [Receptacle] The receptacle which you want to base your substitutions on
  #
  # @return [type] [description]
  def template_asset=(asset)
    @substitutions = asset.aliquots.includes(:sample).map do |aliquot|
      Substitution.new(aliquot: aliquot)
    end
    @name = asset.display_name
  end

  def name
    @name ||= 'Custom'
  end

  private

  def comment_header
    header = +"Tag substitution performed.\n"
    header << "Referenced ticket no: #{@ticket}\n" if @ticket
    header << "Comment: #{@comment}\n" if @comment
    header
  end

  def comment_text
    @comment_text ||= @substitutions.each_with_object(comment_header) do |substitution, comment|
      comment << substitution.comment(oligo_index) << "\n"
    end
  end

  def commented_assets
    @commented_assets ||= (Tube.with_required_aliquots(all_aliquots).pluck(:id) + Lane.with_required_aliquots(all_aliquots).pluck(:id)).uniq
  end

  def apply_comments
    Comment.create!(commented_assets.map do |asset_id|
      { commentable_id: asset_id, commentable_type: 'Asset', user_id: @user&.id, description: comment_text }
    end)
  end

  def oligo_index
    @oligo_index ||= Hash[Tag.find(all_tags).pluck(:id, :oligo)]
  end

  def all_tags
    @all_tags ||= @substitutions.flat_map(&:tag_ids)
  end

  def all_aliquots
    @all_aliquots ||= @substitutions.flat_map(&:matching_aliquots)
  end

  def rebroadcast_lanes
    Lane.with_required_aliquots(all_aliquots).for_rebroadcast.find_each(&:rebroadcast)
  end
end
