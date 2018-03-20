class TagSubstitution::Substitution
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
