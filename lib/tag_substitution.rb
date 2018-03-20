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
