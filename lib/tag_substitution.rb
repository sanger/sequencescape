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
  include ActiveModel::Validations

  validate :substitutions_valid

  def substitutions_valid
    valid = true
    @substitutions.each do |sub|
      next if sub.valid?
      errors.add(:substitution, sub.errors.full_messages)
      valid = false
    end
    valid
  end

  class Substitution
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_reader :sample_id, :library_id, :original_tag_id, :substitute_tag_id, :original_tag2_id, :substitute_tag2_id

    validates_presence_of :sample_id, :library_id
    validates_presence_of :original_tag_id, if: :substitute_tag_id
    validates_presence_of :original_tag2_id, if: :substitute_tag2_id

    validates_presence_of :matching_aliquots, message: 'could not be found'

    def initialize(attributes)
      @sample_id  = attributes.delete(:sample_id)
      @library_id = attributes.delete(:library_id)
      @original_tag_id = attributes.delete(:original_tag_id)
      @substitute_tag_id = attributes.delete(:substitute_tag_id)
      @original_tag2_id = attributes.delete(:original_tag2_id)
      @substitute_tag2_id = attributes.delete(:substitute_tag2_id)
      @other_attributes = attributes
    end

    def matching_aliquots
      @matching_aliquots ||= find_matching_aliquots
    end

    def rebroadcast_lanes
      Lane.with_required_aliquots(matching_aliquots).each(&:rebroadcast)
    end

    # Nullify tags sets all tags to null. We need to do this first
    # as otherwise we introduce tag clashes while performing substitutions
    def nullify_tags
      tags_hash = {}
      tags_hash[:tag_id]  = nil if original_tag_id
      tags_hash[:tag2_id] = nil if original_tag2_id
      # We DO NOT want to trigger validations here
      Aliquot.where(id: matching_aliquots).update_all(tags_hash) if tags_hash.present? # rubocop:disable Rails/SkipsModelValidations
    end

    def substitute_tags
      Aliquot.where(id: matching_aliquots).find_each do |aliquot|
        aliquot.tag_id = substitute_tag_id if original_tag_id
        aliquot.tag2_id = substitute_tag2_id if original_tag2_id
        aliquot.update_attributes(@other_attributes)
        aliquot.save!
      end
      rebroadcast_lanes
    end

    private

    def find_matching_aliquots
      attributes = { sample_id: sample_id, library_id: library_id }
      attributes[:tag_id] = original_tag_id if original_tag_id
      attributes[:tag2_id] = original_tag2_id if original_tag2_id
      Aliquot.where(attributes).pluck(:id)
    end
  end
  # substitutions: Provide an array of hashes describing your desired substitutions
  # {
  #   sample_id: The id of the sample to change,
  #   libary_id: The corresponding library id,
  #   original_tag_id: The original tag id, [Required if substitute_tag_id supplied]
  #   substitute_tag_id: the replacement tag id, [Optional]
  #   original_tag2_id: The original tag2 id, [Required if original_tag2_id supplied]
  #   substitute_tag2_id: The replacement tag2 id [Optional]
  # }
  # Named arguments:
  # user: the user performing the substitution [optional]
  # ticket: support ticket number [optional]
  # comment: any additional comment [optional]
  def initialize(substitutions, user: nil, ticket: nil, comment: nil)
    @user, @ticket, @comment = user, ticket, comment
    @substitutions = substitutions.map { |attrs| Substitution.new(attrs) }
  end

  def save
    return false unless valid?
    # First set all tags to null to avoid the issue of tag clashes
    ActiveRecord::Base.transaction do
      @substitutions.each(&:nullify_tags)
      @substitutions.each(&:substitute_tags)
    end
    true
  end
end
