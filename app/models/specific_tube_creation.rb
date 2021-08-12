# Allows a different purpose to be set for each of the child tubes.
class SpecificTubeCreation < TubeCreation
  # Allows a many to many relationship between SpecificTubeCreations and Purposes.
  class ChildPurpose < ApplicationRecord
    self.table_name = 'specific_tube_creation_purposes'
    belongs_to :specific_tube_creation
    belongs_to :tube_purpose, class_name: 'Purpose'
  end

  has_many :creation_child_purposes, class_name: 'SpecificTubeCreation::ChildPurpose'
  has_many :child_purposes, through: :creation_child_purposes, source: :tube_purpose

  validates :child_purposes, presence: true

  has_many :parent_associations,
           foreign_key: 'asset_creation_id',
           class_name: 'AssetCreation::ParentAssociation',
           inverse_of: 'asset_creation'
  has_many :parents, through: :parent_associations, class_name: 'Labware'

  # [Array<Hash>] An optional array of hashes which get passed in to the create! action
  #               on tube_purpose.
  #               Allows overriding default attributes, or setting custom
  #               values for. eg. name.
  #               eg. [{ name: 'Tube one' }, { name: 'Tube two' }]
  attr_writer :tube_attributes

  def set_parents=(uuids)
    self.parents = uuids.map { |uuid| Uuid.find_by(external_id: uuid).resource }
    self.parent = parents.first
  end

  def set_parent=(uuid)
    parent = Uuid.find_by(external_id: uuid).resource
    self.parents = [parent]
    self.parent = parent
  end

  def set_child_purposes=(uuids)
    self.child_purposes = uuids.map { |uuid| Uuid.find_by(external_id: uuid).resource }
  end

  def multiple_purposes
    true
  end

  # If no tube attributes are specified, fall back to an array of empty hashes
  def tube_attributes
    @tube_attributes || Array.new(child_purposes.length, {})
  end

  private

  def no_pooling_expected?
    true
  end

  def create_children!
    self.children =
      child_purposes.each_with_index.map do |child_purpose, index|
        # For each tube purpose listed in the child_purposes array
        # create a tube via the tube purpose factory, passing in our
        # custom attributes.
        child_purpose.create!(tube_attributes[index])
      end
  end
end
