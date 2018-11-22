# frozen_string_literal: true

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

  attr_accessor :user, :ticket, :comment
  attr_reader :substitutions
  attr_writer :name

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

  validates :substitutions, presence: true
  validate :substitutions_valid?, if: :substitutions
  validate :no_duplicate_tag_pairs, if: :substitutions

  def substitutions_valid?
    @substitutions.reduce(true) do |valid, sub|
      next valid if sub.valid?

      errors.add(:substitution, sub.errors.full_messages)
      valid && false
    end
  end

  def substitutions=(substitutions)
    @substitutions = substitutions.map { |attrs| Substitution.new(attrs.dup) }
  end

  def save
    return false unless valid?

    # First set all tags to null to avoid the issue of tag clashes
    ActiveRecord::Base.transaction do
      @substitutions.each(&:nullify_tags)
      @substitutions.each(&:substitute_tags)
      apply_comments
    end
    rebroadcast_flowcells
    true
  rescue ActiveRecord::RecordNotUnique => exception
    # We'll specifically handle tag clashes here so that we can produce more informative messages
    raise exception unless /aliquot_tags_and_tag2s_are_unique_within_receptacle/.match?(exception.message)

    errors.add(:base, 'A tag clash was detected while performing the substitutions. No changes have been made.')
    false
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

  def no_duplicate_tag_pairs
    tag_pairs.each_with_object(Set.new) do |pair, set|
      errors.add(:base, "Tag pair #{pair.join('-')} features multiple times in the pool.") if set.include?(pair)
      set << pair
    end
  end

  private

  def tag_pairs
    @substitutions.each_with_object([]) do |sub, substitutions|
      next unless sub.tag_substitutions?

      tag, tag2 = sub.tag_pair
      substitutions << [oligo_index[tag], oligo_index[tag2]]
    end
  end

  def comment_header
    header = +"Tag substitution performed.\n"
    header << "Referenced ticket no: #{@ticket}\n" if @ticket.present?
    header << "Comment: #{@comment}\n" if @comment.present?
    header
  end

  def comment_text
    @comment_text ||= @substitutions.each_with_object(comment_header) do |substitution, comment|
      substitution_comment = substitution.comment(oligo_index)
      comment << substitution_comment << "\n" if substitution_comment.present?
    end
  end

  def commented_assets
    @commented_assets ||= (Tube.with_required_aliquots(all_aliquots).pluck(:id) + lane_ids).uniq
  end

  def apply_comments
    Comment.import(commented_assets.map do |asset_id|
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

  def lane_ids
    @lane_ids ||= Lane.with_required_aliquots(all_aliquots).pluck(:id)
  end

  def rebroadcast_flowcells
    Batch.joins(:requests).where(requests: { target_asset_id: lane_ids }).distinct.each(&:rebroadcast)
  end
end
