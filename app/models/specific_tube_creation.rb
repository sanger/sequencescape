# frozen_string_literal: true
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

  # rubocop:todo Layout/LineLength
  has_many :parents, through: :parent_associations, class_name: 'Labware' # also has a belongs_to inherited from TubeCreation

  # rubocop:enable Layout/LineLength

  # [Array<Hash>] An optional array of hashes which get passed in to the create! action
  #               on tube_purpose.
  #               Allows overriding default attributes, or setting custom
  #               values for. eg. name.
  #               eg. [{ name: 'Tube one' }, { name: 'Tube two' }]
  attr_writer :tube_attributes

  # singular 'parent' getter to stay backwards compatible
  def parent
    parents.first
  end

  # singular 'parent' setter to stay backwards compatible
  def parent=(parent)
    self.parents = [parent]
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

  def connect_parent_and_children
    parents.each { |parent| children.each { |child| AssetLink.create_edge!(parent, child) } }
  end
  private :connect_parent_and_children

  def determine_foreign_barcode_format(foreign_barcode)
    Barcode.matching_barcode_format(foreign_barcode)
  end

  def check_foreign_barcode_unique(foreign_barcode_format, foreign_barcode)
    return unless Barcode.exists_for_format?(foreign_barcode_format, foreign_barcode)

    raise "Foreign Barcode: #{foreign_barcode} is already in use!"
  end

  def add_foreign_barcode_to_tube(tube, foreign_barcode)
    foreign_barcode_format = determine_foreign_barcode_format(foreign_barcode)

    raise "Cannot determine format for foreign barcode #{foreign_barcode}" if foreign_barcode_format.blank?

    check_foreign_barcode_unique(foreign_barcode_format, foreign_barcode)

    # add the foreign barcode to the tube (will be the primary barcode)
    tube.barcodes << Barcode.new(format: foreign_barcode_format, barcode: foreign_barcode)
  end

  def create_children!
    self.children =
      child_purposes.each_with_index.map do |child_purpose, index|
        # For each tube purpose listed in the child_purposes array
        # create a tube via the tube purpose factory, passing in our
        # custom attributes.
        tube_detail = tube_attributes[index].symbolize_keys

        # extract foreign barcode for use after the create if one has been set
        foreign_barcode = tube_detail.delete(:foreign_barcode)

        child_purpose.create!(tube_detail) do |tube|
          add_foreign_barcode_to_tube(tube, foreign_barcode) if foreign_barcode.present?
        end
      end
  end
end
