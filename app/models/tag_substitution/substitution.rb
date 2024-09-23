# frozen_string_literal: true

# Used by TagSubstitution to handle the individual substitutions per
# library.
#
# @author [grl]
#
class TagSubstitution::Substitution # rubocop:todo Metrics/ClassLength
  include ActiveModel::Model

  attr_accessor :sample_id, :library_id
  attr_reader :tag_substitution,
              :original_tag_id,
              :substitute_tag_id,
              :original_tag2_id,
              :substitute_tag2_id,
              :tag_substituter

  delegate :disable_match_expectation, to: :tag_substituter, allow_nil: true

  delegate :friendly_name, to: :sample, prefix: true
  validates :sample_id, presence: true
  validates :original_tag_id, presence: { if: :substitute_tag_id }
  validates :original_tag2_id, presence: { if: :substitute_tag2_id }
  validates :matching_aliquots, presence: { message: 'could not be found' }, unless: :disable_match_expectation

  #
  # Generate a tag substitutes for a single library
  # @param attributes [Hash] Details describing the library and its new state
  #   sample_id: The sample_id for the aliquots to update
  #   library_id: The library_id for the aliquots to update
  #   original_tag_id: The current tag_id of the aliquots to update
  #   substitute_tag_id: The new tag_id of the aliquots to update
  #   original_tag2_id: The current tag2_id of the aliquots to update
  #   substitute_tag2_id: The new tag2_id of the aliquots to update
  #   OR
  #   aliquot: Provide an aliquot to act as a template. Useful for pre-populating forms
  # @param tag_substituter [TagSubstitution] The parent tag substituter
  def initialize(attributes, tag_substituter = nil) # rubocop:todo Metrics/MethodLength
    super(
      attributes.extract!(
        :sample_id,
        :library_id,
        :original_tag_id,
        :substitute_tag_id,
        :original_tag2_id,
        :substitute_tag2_id,
        :aliquot
      )
    )
    @other_attributes = attributes
    @tag_substituter = tag_substituter
  end

  def original_tag_id=(tag_id)
    @original_tag_id = tag_id.to_i if tag_id.present?
  end

  def substitute_tag_id=(tag_id)
    @substitute_tag_id = tag_id.to_i if tag_id.present?
  end

  def original_tag2_id=(tag2_id)
    @original_tag2_id = tag2_id.to_i if tag2_id.present?
  end

  def substitute_tag2_id=(tag2_id)
    @substitute_tag2_id = tag2_id.to_i if tag2_id.present?
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

  # Returns the sample. Caution! Will be slow if not populated by aliquot
  def sample
    @sample ||= Sample.find(@sample_id)
  end

  # All aliquots which match the criteria
  # @return [Array<Integer>] An array of aliquot ids.
  def matching_aliquots
    @matching_aliquots ||= find_matching_aliquots
  end

  # Nullify tags sets all tags to null. We need to do this first
  # as otherwise we introduce tag clashes while performing substitutions
  def nullify_tags
    tags_hash = {}
    tags_hash[:tag_id] = nil if substitute_tag?
    tags_hash[:tag2_id] = nil if substitute_tag2?

    # We DO NOT want to trigger validations here
    Aliquot.where(id: matching_aliquots).update_all(tags_hash) if tags_hash.present? # rubocop:disable Rails/SkipsModelValidations
  end

  #
  # Applies the new tags to the aliquots.
  #
  # @return [Void]
  def substitute_tags
    Aliquot
      .where(id: matching_aliquots)
      .find_each do |aliquot|
        aliquot.tag_id = substitute_tag_id if substitute_tag?
        aliquot.tag2_id = substitute_tag2_id if substitute_tag2?
        aliquot.update(@other_attributes) if @other_attributes.present?
        aliquot.save!
      end
  end

  #
  # Generates a comment to describe the substitutions performed
  # The oligo index is passed in as part of a performance optimiztion to avoid repeated hits to the database to fetch
  # oligo sequences
  # @param oligo_index [Hash] A hash of oligo sequences indexed by oligo id.
  #
  # @return [String] A description of the substitution
  def comment(oligo_index) # rubocop:todo Metrics/AbcSize
    return '' unless updated?

    comment = +"Sample #{sample_id}:"
    if substitute_tag?
      comment << " Tag changed from #{oligo_index[original_tag_id]} to #{oligo_index[substitute_tag_id]};"
    end
    if substitute_tag2?
      comment << " Tag2 changed from #{oligo_index[original_tag2_id]} to #{oligo_index[substitute_tag2_id]};"
    end
    @other_attributes.each { |k, v| comment << " #{k} changed to #{v};" }
    comment
  end

  #
  # Returns an array of all associated tag ids. Excludes untagged representation (typically -1)
  #
  # @return [Array<Integer>] All tag ids which should correspond to actual tags. -1, nil etc. are ignored.
  def tag_ids
    [original_tag_id, substitute_tag_id, original_tag2_id, substitute_tag2_id].select { |id| id&.positive? }
  end

  #
  # A two value array representing the tag ids AFTER substitution.
  #
  # @return [Array<Integer>] Array of tag_id, followed by tag2_id.
  def tag_pair
    [substitute_tag_id, substitute_tag2_id]
  end

  def tag_substitutions?
    original_tag_id || original_tag2_id
  end

  def updated?
    substitute_tag? || substitute_tag2? || @other_attributes.present?
  end

  private

  def substitute_tag?
    original_tag_id && original_tag_id != substitute_tag_id
  end

  def substitute_tag2?
    original_tag2_id && original_tag2_id != substitute_tag2_id
  end

  def find_matching_aliquots
    attributes = { sample_id:, library_id: }
    attributes[:tag_id] = original_tag_id if original_tag_id
    attributes[:tag2_id] = original_tag2_id if original_tag2_id
    Aliquot.where(attributes).ids
  end
end
