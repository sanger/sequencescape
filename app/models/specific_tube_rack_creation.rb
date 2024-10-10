# frozen_string_literal: true
# Allows for the creation of multiple tube racks and their tubes.
class SpecificTubeRackCreation < AssetCreation
  # Allows a many to many relationship between SpecificTubeRackCreations and child Tube racks.
  class ChildTubeRack < ApplicationRecord
    self.table_name = ('specific_tube_rack_creation_children')
    belongs_to :specific_tube_rack_creation
    belongs_to :tube_rack
  end

  # Allows a many to many relationship between SpecificTubeRackCreations and Purposes.
  class ChildPurpose < ApplicationRecord
    self.table_name = 'specific_tube_rack_creation_purposes'
    belongs_to :specific_tube_rack_creation
    belongs_to :tube_rack_purpose, class_name: 'TubeRack::Purpose'
  end

  has_many :creation_child_purposes, class_name: 'SpecificTubeRackCreation::ChildPurpose', dependent: :destroy
  has_many :child_purposes, through: :creation_child_purposes, source: :tube_rack_purpose

  has_many :child_tube_racks, class_name: 'SpecificTubeRackCreation::ChildTubeRack', dependent: :destroy
  has_many :children, through: :child_tube_racks, source: :tube_rack

  validates :tube_rack_attributes, presence: true

  has_many :parent_associations,
           foreign_key: 'asset_creation_id',
           class_name: 'AssetCreation::ParentAssociation',
           inverse_of: 'asset_creation',
           dependent: :destroy

  # TODO: why do we have both of these?
  # NB. assumption that parent is a plate
  belongs_to :parent, class_name: 'Plate'
  has_many :parents, through: :parent_associations, class_name: 'Plate'

  #   @param value [Array<Hash>] Hashes defining the attributes to apply to each tube rack and
  #     the tubes within that are being created.
  #     This is used to set custom attributes on the tube racks, such as name. As well as to create
  #     the tubes within the tube rack and link them together.
  #   @example [
  #   {
  #     :tube_rack_name=>"Tube Rack",
  #     :tube_rack_barcode=>"TR00000001",
  #     :tube_rack_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
  #     :tube_rack_metadata_key=>"tube_rack_barcode",
  #     :racked_tubes=>[
  #       {
  #         :tube_barcode=>"SQ45303801",
  #         :tube_name=>"SEQ:NT749R:A1",
  #         :tube_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
  #         :tube_position=>"A1",
  #         :parent_uuids=>["bd49e7f8-80a1-11ef-bab6-82c61098d1a0"]
  #       },
  #       etc... more tubes
  #     ]
  #   },
  #   etc... more tube racks
  attr_writer :tube_rack_attributes

  DEFAULT_TARGET_TYPE = 'TubeRack'

  # singular 'parent' getter to stay backwards compatible
  def parent
    parents.first
  end

  # singular 'parent' setter to stay backwards compatible
  def parent=(parent)
    self.parents = [parent]
  end

  # If no tube rack attributes are specified, fall back to an empty array
  def tube_rack_attributes
    @tube_rack_attributes || Array.new(child_purposes.length, {})
  end

  # See asset_creation, flag to indicate that multiple child purposes are expected and skip validation
  def multiple_purposes
    true
  end

  private

  def target_for_ownership
    children
  end

  # Connect parent labware to child tube racks
  # Method overridden from AssetCreation
  def connect_parent_and_children
    parents.each { |parent| children.each { |child| AssetLink.create_edge!(parent, child) } }
  end

  # Creates child tube racks based on the provided tube rack attributes.
  #
  # This method iterates over the @tube_rack_attributes array and creates a child tube rack
  # for each set of attributes. The created child tube racks are assigned to the `children`
  # attribute of the current object.
  #
  # @raise [StandardError] if any of the child tube rack creation processes fail.
  #
  # @return [Array<TubeRack>] An array of the created child tube racks.
  def create_children!
    self.children =
      @tube_rack_attributes.each_with_index.map { |rack_attributes, _index| create_child_tube_rack(rack_attributes) }
  end

  # Creates a child tube rack based on the provided rack attributes.
  #
  # This method performs the following steps:
  # 1. Finds the child purpose using the provided tube rack purpose UUID.
  # 2. Adds the found child purpose to the `child_purposes` attribute.
  # 3. Creates a new tube rack with the provided name under the found child purpose.
  # 4. Handles the tube rack barcode, either creating a new barcode or redirecting an existing one.
  # 5. Adds metadata to the new tube rack using the provided metadata key and barcode.
  #
  # @param [Hash] rack_attributes The attributes for the tube rack, including:
  #   - :tube_rack_purpose_uuid [String] The UUID of the tube rack purpose.
  #   - :tube_rack_name [String] The name of the tube rack.
  #   - :tube_rack_barcode [String] The barcode of the tube rack.
  #   - :tube_rack_metadata_key [String] The metadata key for the tube rack.
  #
  # @raise [StandardError] if any of the tube rack creation processes fail.
  #
  # @return [TubeRack] The created tube rack.
  def create_child_tube_rack(rack_attributes)
    child_purpose = find_child_purpose(rack_attributes[:tube_rack_purpose_uuid])
    child_purposes << child_purpose

    new_tube_rack = child_purpose.create!(name: rack_attributes[:tube_rack_name])
    handle_tube_rack_barcode(rack_attributes[:tube_rack_barcode], new_tube_rack)
    add_tube_rack_metadata(rack_attributes[:tube_rack_metadata_key], rack_attributes[:tube_rack_barcode], new_tube_rack)

    new_tube_rack
  end

  # Finds the child purpose using the provided UUID.
  #
  # This method queries the TubeRack::Purpose model to find the first record
  # that matches the given UUID. If a matching record is found, it is returned.
  # If no matching record is found, an error is raised.
  #
  # @param [String] uuid The UUID of the tube rack purpose to find.
  #
  # @raise [StandardError] if no matching TubeRack::Purpose record is found.
  #
  # @return [TubeRack::Purpose] The found TubeRack::Purpose object.
  def find_child_purpose(uuid)
    tr_purpose = TubeRack::Purpose.with_uuid(uuid).first
    return tr_purpose if tr_purpose

    error_message = "The tube rack purpose with UUID '#{uuid}' was not found."
    raise StandardError, error_message
  end

  # Handles the barcode assignment for a new tube rack.
  #
  # This method checks if a barcode already exists for the given tube rack barcode.
  # If the barcode does not exist, it creates a new barcode for the tube rack.
  # If the barcode already exists, it redirects the existing barcode to the new tube rack instance.
  # This is done to allow the re-use of the physical tube rack, which has an etched barcode.
  #
  # @param [String] tube_rack_barcode The barcode of the tube rack.
  # @param [TubeRack] new_tube_rack The new tube rack object to which the barcode will be assigned.
  #
  # @raise [StandardError] if the barcode cannot be created or redirected.
  #
  # @return [void]
  def handle_tube_rack_barcode(tube_rack_barcode, new_tube_rack)
    existing_barcode_record = Barcode.includes(:asset).find_by(asset_id: tube_rack_barcode)

    if existing_barcode_record.nil?
      create_new_barcode(tube_rack_barcode, new_tube_rack)
    else
      redirect_existing_barcode(existing_barcode_record, new_tube_rack, tube_rack_barcode)
    end
  end

  # Creates a new barcode for the given tube rack.
  #
  # This method checks if the provided tube rack barcode matches a recognized format.
  # If the barcode format is valid, it creates a new Barcode record associated with the new tube rack.
  # If the barcode format is not recognized, it raises an error.
  #
  # @param [String] tube_rack_barcode The barcode of the tube rack.
  # @param [TubeRack] new_tube_rack The new tube rack object to which the barcode will be assigned.
  #
  # @raise [StandardError] if the barcode format is not recognized.
  #
  # @return [Barcode] The created Barcode object.
  def create_new_barcode(tube_rack_barcode, new_tube_rack)
    barcode_format = Barcode.matching_barcode_format(tube_rack_barcode)
    if barcode_format.nil?
      error_message = "The tube rack barcode '#{tube_rack_barcode}' is not a recognised format."
      raise StandardError, error_message
    end
    Barcode.create!(labware: new_tube_rack, barcode: tube_rack_barcode, format: barcode_format)
  end

  # Redirects an existing barcode to a new tube rack.
  #
  # This method checks if the existing barcode is associated with a TubeRack.
  # If it is, the barcode is reassigned to the new tube rack.
  # If it is not, an error is raised indicating that the barcode is already in use by another type of labware.
  #
  # @param [Barcode] existing_barcode_record The existing Barcode record to be redirected.
  # @param [TubeRack] new_tube_rack The new tube rack object to which the barcode will be reassigned.
  # @param [String] tube_rack_barcode The barcode of the tube rack.
  #
  # @raise [StandardError] if the barcode is already in use by another type of labware.
  #
  # @return [void]
  def redirect_existing_barcode(existing_barcode_record, new_tube_rack, tube_rack_barcode)
    existing_labware = existing_barcode_record.labware

    if existing_labware.is_a?(TubeRack)
      existing_barcode_record.labware = new_tube_rack
    else
      error_message =
        "The tube rack barcode '#{tube_rack_barcode}' is already in use by " \
          'another type of labware, cannot create tube rack.'
      raise StandardError, error_message
    end
  end

  # Adds metadata to a tube rack.
  #
  # This method creates a new PolyMetadatum record with the provided metadata key and tube rack barcode.
  # The metadatable_type and metadatable_id are set to the class and ID of the tube rack, respectively.
  # If the metadata record fails to save, an error is raised.
  #
  # @param [String] metadata_key The key for the metadata.
  # @param [String] tube_rack_barcode The barcode of the tube rack to be used as the metadata value.
  # @param [TubeRack] tube_rack The tube rack object to which the metadata will be added.
  #
  # @raise [StandardError] if the metadata record fails to save.
  #
  # @return [void]
  def add_tube_rack_metadata(metadata_key, tube_rack_barcode, tube_rack)
    pm =
      PolyMetadatum.new(
        key: metadata_key,
        value: tube_rack_barcode,
        metadatable_type: tube_rack.class,
        metadatable_id: tube_rack.id
      )
    return if pm.save

    raise StandardError, "New metadata for tube rack (key: #{metadata_key}, value: #{tube_rack_barcode}) did not save"
  end

  # Inherited from AssetCreation
  def record_creation_of_children
    # Not generating creation events for this labware
  end
end
