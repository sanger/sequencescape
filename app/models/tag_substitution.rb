# frozen_string_literal: true

# A TagSubstitution may be used to replace tags in the event of
# accidental miss-tagging.
#
# @example Populating from an existing asset
#  mistagged_lane = Lane.find(1234)
#  TagSubstitution.new(tameplate_asset: mistagged_lane)
#
# @example Swapping two tags in response to an RT ticket
#  TagSubstitution.new(
#    user: User.find_by(login: 'ab12'),
#    ticket: 'RT#12345',
#    comment: 'Accidental tag swap',
#    substitutions: [
#      {
#        sample_id: 100, libary_id: 10,
#        original_tag_id: 20, substitute_tag_id: 21,
#        original_tag2_id: 200, substitute_tag2_id: 201
#      },
#      {
#        sample_id: 101, libary_id: 11,
#        original_tag_id: 21, substitute_tag_id: 20,
#        original_tag2_id: 201, substitute_tag2_id: 200
#      }
#    ]
#  ).save #=> true
class TagSubstitution
  include ActiveModel::Model

  # The user performing the substitution, gets recorded on the generated comments [optional]
  # @return [User] the user performing the substitution
  attr_accessor :user

  # The ticket number associated with the substitution, eg RT#123454. Gets recorded in
  # the generated comment [optional]
  # @return [String] ticket number
  attr_accessor :ticket

  # Any additional comments regarding the substitution [optional]
  # @return [String] free-text comment field
  attr_accessor :comment

  # Disable tag-clash detection. Useful in cases where the substitutions only affect one of a pair of tags
  # which is ensuring uniqueness, or where the updated aliquots are not part of a pool.
  # @return [Boolean] indicates if clash detection is disabled
  attr_accessor :disable_clash_detection

  # Disable match-detection. Match detection flags a substitution as invalid if it cannot find aliquots
  # matching the suggested substitution. This can be disabled in cases where this may be expected,
  # such as in re-upload of library manifests. (As the aliquots in the library tubes themselves will
  # have been updated by the manifest)
  # @return [Boolean] indicates if match detection
  attr_accessor :disable_match_expectation

  # Provide an array of hashes describing your desired substitutions
  #   {
  #     sample_id: The id of the sample to change,
  #     libary_id: The corresponding library id,
  #     original_tag_id: The original tag id, [Required if substitute_tag_id supplied]
  #     substitute_tag_id: the replacement tag id, [Optional]
  #     original_tag2_id: The original tag2 id, [Required if original_tag2_id supplied]
  #     substitute_tag2_id: The replacement tag2 id [Optional]
  #   }
  # @return [Hash] the substitutions to perform
  attr_reader :substitutions

  # Used by the view to provide feedback to the user about which asset they are about to
  # perform substitutions on. Set if a template_asset is user. Otherwise is 'Custom'
  # @return [String] The display name of the template_asset
  attr_writer :name

  validates :substitutions, presence: true
  validate :substitutions_valid?, if: :substitutions
  validate :no_duplicate_tag_pairs, if: :substitutions, unless: :disable_clash_detection

  def substitutions_valid?
    @substitutions.reduce(true) do |valid, sub|
      next valid if sub.valid?

      errors.add(:substitution, sub.errors.full_messages)
      valid && false
    end
  end

  def substitutions=(substitutions)
    @substitutions = substitutions.map { |attrs| Substitution.new(attrs.dup, self) }
  end

  def updated_substitutions
    @updated_substitutions ||= @substitutions.select(&:updated?)
  end

  # Perform the substitution, add comments to all tubes and lanes and rebroadcast all flowcells
  # @return [Boolean] returns true if the operation was successful, false otherwise
  def save # rubocop:todo Metrics/MethodLength
    return false unless valid?

    # First set all tags to null to avoid the issue of tag clashes
    ActiveRecord::Base.transaction do
      updated_substitutions.each(&:nullify_tags)
      updated_substitutions.each(&:substitute_tags)
      apply_comments
      rebroadcast_flowcells
    end
    true
  rescue ActiveRecord::RecordNotUnique => e
    # We'll specifically handle tag clashes here so that we can produce more informative messages
    raise e unless e.message.include?('aliquot_tag_tag2_and_tag_depth_are_unique_within_receptacle')

    errors.add(:base, 'A tag clash was detected while performing the substitutions. No changes have been made.')
    false
  end

  #
  # Provide an asset to build a tag substitution form
  # Will auto populate the fields on substitutions
  # @param asset [Receptacle] The receptacle which you want to base your substitutions on
  #
  # @return [void]
  def template_asset=(asset)
    @substitutions = asset.aliquots.includes(:sample).map { |aliquot| Substitution.new(aliquot:) }
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
    @comment_text ||=
      updated_substitutions.each_with_object(comment_header) do |substitution, comment|
        substitution_comment = substitution.comment(oligo_index)
        comment << substitution_comment << "\n" if substitution_comment.present?
      end
  end

  def commented_assets
    @commented_assets ||= (Receptacle.on_a(Tube).with_required_aliquots(all_aliquots).pluck(:id) + lane_ids).uniq
  end

  def apply_comments
    commentable_type = Receptacle.base_class.name
    Comment.import(
      commented_assets.map do |asset_id|
        {
          commentable_id: asset_id,
          commentable_type:,
          user_id: @user&.id,
          description: comment_text,
          title: "Tag Substitution #{@ticket}"
        }
      end
    )
  end

  def oligo_index
    @oligo_index ||= Tag.find(all_tags).pluck(:id, :oligo).to_h
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
    # Touch updates the batch (and hence message timestamp) and triggers the after_comit callback
    # which broadcasts the batch.
    Batch.joins(:requests).where(requests: { target_asset_id: lane_ids }).distinct.each(&:touch)
  end
end
