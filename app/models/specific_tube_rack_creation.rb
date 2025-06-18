# frozen_string_literal: true
# Allows for the creation of multiple tube racks and their tubes.
# rubocop:disable Metrics/ClassLength
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
    belongs_to :tube_rack_purpose, class_name: 'Purpose'
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
    # initialise tube purposes hash to avoid multiple queries
    @tube_purposes = {}

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
  # 6. Creates the tubes for the new tube rack using the provided tube attributes.
  #
  # @param [Hash] rack_attributes The attributes for the tube rack, including:
  #   - :tube_rack_purpose_uuid [String] The UUID of the tube rack purpose.
  #   - :tube_rack_name [String] The name of the tube rack.
  #   - :tube_rack_barcode [String] The barcode of the tube rack.
  #   - :racked_tubes [Array<Hash>] An array of hashes defining the tubes to be created within the tube rack.
  #
  # @raise [StandardError] if any of the tube rack creation processes fail.
  #
  # @return [TubeRack] The created tube rack.
  def create_child_tube_rack(rack_attributes)
    child_purpose = find_tube_rack_purpose(rack_attributes[:tube_rack_purpose_uuid])
    child_purposes << child_purpose

    new_tube_rack = child_purpose.create!(name: rack_attributes[:tube_rack_name])
    handle_tube_rack_barcode(rack_attributes[:tube_rack_barcode], new_tube_rack)
    add_tube_rack_metadata(rack_attributes[:tube_rack_barcode], new_tube_rack)

    create_racked_tubes(rack_attributes[:racked_tubes], new_tube_rack)

    new_tube_rack
  end

  # Finds the tube rack purpose using the provided UUID.
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
  def find_tube_rack_purpose(uuid)
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
    existing_barcode_record = Barcode.includes(:asset).find_by(barcode: tube_rack_barcode)

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
      existing_barcode_record.save!
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
  # @param [String] tube_rack_barcode The barcode of the tube rack to be used as the metadata value.
  # @param [TubeRack] tube_rack The tube rack object to which the metadata will be added.
  #
  # @raise [StandardError] if the metadata record fails to save.
  #
  # @return [void]
  def add_tube_rack_metadata(tube_rack_barcode, tube_rack)
    metadata_key = Rails.application.config.tube_racks_config[:tube_rack_barcode_key]
    pm =
      PolyMetadatum.new(
        key: metadata_key,
        value: tube_rack_barcode,
        metadatable_type: tube_rack.class.name,
        metadatable_id: tube_rack.id
      )
    return if pm.save

    raise StandardError, "New metadata for tube rack (key: #{metadata_key}, value: #{tube_rack_barcode}) did not save"
  end

  # Creates racked tubes based on the provided attributes and associates them with a new tube rack.
  #
  # This method iterates over the array of racked tube attributes provided in the rack_attributes
  # hash.
  # For each set of tube attributes, it calls the create_racked_tube method to create and associate
  # the tube with the new tube rack.
  #
  # @param [Array<Hash>] racked_tubes An array of hashes, each containing attributes for a racked tube.
  # @param [TubeRack] new_tube_rack The new tube rack object to which the tubes will be associated.
  #
  # @raise [StandardError] if any of the tube creation processes fail.
  #
  # @return [void]
  def create_racked_tubes(racked_tubes, new_tube_rack)
    # iterate through the rack attributes to create each tube
    racked_tubes.each { |tube_attributes| create_racked_tube(tube_attributes, new_tube_rack) }
  end

  def create_racked_tube(tube_attributes, new_tube_rack)
    tube = create_tube(tube_attributes)
    link_tube_to_rack(tube, new_tube_rack, tube_attributes[:tube_position])
  end

  # Ensures that the provided tube barcode is unique.
  #
  # This method checks if a tube barcode already exists in the database.
  # If the barcode is found, it raises a StandardError indicating that the barcode is already in use.
  # If the barcode is not found, the method simply returns, allowing the process to continue.
  #
  # @param [String] tube_barcode The barcode of the tube to be checked for uniqueness.
  #
  # @raise [StandardError] if the tube barcode is already in use.
  #
  # @return [void]
  def ensure_unique_tube_barcode(tube_barcode)
    existing_tube_barcode_record = Barcode.includes(:asset).find_by(asset_id: tube_barcode)
    return if existing_tube_barcode_record.nil?

    error_message = "The tube barcode '#{tube_barcode}' is already in use, cannot continue."
    raise StandardError, error_message
  end

  # Checks the format of the provided tube barcode.
  #
  # This method verifies that the provided tube barcode matches a recognized format.
  # It first checks if the barcode format is recognized. If not, it raises a StandardError.
  # Then, it checks if the barcode format is of the expected 'fluidx_barcode' type.
  # If the barcode format is not 'fluidx_barcode', it raises a StandardError.
  #
  # @param [String] tube_barcode The barcode of the tube to be checked.
  #
  # @raise [StandardError] if the barcode format is not recognized or if it is not of the
  # expected 'fluidx_barcode' type.
  #
  # @return [void]
  def check_tube_barcode_format(tube_barcode)
    barcode_format = Barcode.matching_barcode_format(tube_barcode)

    # barcode format should be recognised
    if barcode_format.nil?
      error_message = "The tube barcode '#{tube_barcode}' is not a recognised format."
      raise StandardError, error_message
    end

    # expecting fluidx format
    return if barcode_format == :fluidx_barcode

    error_message = "The tube barcode '#{tube_barcode}' is not of the expected fluidx type."
    raise StandardError, error_message
  end

  # Creates a new tube based on the provided attributes.
  #
  # This method performs the following steps:
  # 1. Extracts the tube barcode from the provided tube attributes.
  # 2. Checks if the tube barcode format is valid.
  # 3. Ensures that the tube barcode is unique by checking for existing records.
  # 4. Checks if the tube purpose UUID is valid and fetches the corresponding tube purpose.
  # 5. Creates the tube via the tube purpose with the provided name.
  # 6. Sets the foreign barcode after initial creation to ensure it is set as the 'primary' barcode.
  # 7. Reloads the tube to ensure all attributes are up-to-date.
  #
  # @param [Hash] tube_attributes The attributes for the tube, including:
  #   - :tube_barcode [String] The barcode of the tube.
  #   - :tube_name [String] The name of the tube.
  #   - :tube_purpose_uuid [String] The UUID of the tube purpose.
  #
  # @raise [StandardError] if any of the validation or creation processes fail.
  #
  # @return [Tube] The created Tube object.
  def create_tube(tube_attributes)
    tube_barcode = tube_attributes[:tube_barcode]

    # check barcode format is valid
    check_tube_barcode_format(tube_barcode)

    # check barcode is not in use
    ensure_unique_tube_barcode(tube_barcode)

    # check tube purpose uuid is valid and fetch tube purpose
    tube_purpose = find_tube_purpose(tube_attributes[:tube_purpose_uuid])

    # create the tube via the tube purpose
    tube = tube_purpose.create!(name: tube_attributes[:tube_name])

    # set the foreign barcode is after initial creation to ensure the barcode is set as the 'primary' barcode
    tube.foreign_barcode = tube_barcode
    tube.reload
  end

  # Links a tube to a tube rack at a specified position.
  #
  # This method creates a new RackedTube object that associates the provided tube
  # with the specified tube rack at the given position. The RackedTube object is then saved to the database.
  #
  # @param [Tube] tube The tube object to be linked to the tube rack.
  # @param [TubeRack] new_tube_rack The tube rack object to which the tube will be linked.
  # @param [String] tube_position The position of the tube in the tube rack.
  #
  # @raise [ActiveRecord::RecordInvalid] if the RackedTube object fails to save.
  #
  # @return [void]
  def link_tube_to_rack(tube, new_tube_rack, tube_position)
    racked_tube = RackedTube.new(tube: tube, tube_rack: new_tube_rack, coordinate: tube_position)
    return if racked_tube.save!

    error_message =
      "The tube '#{tube.name}' could not be linked to the tube rack '#{new_tube_rack.name}' " \
      "at position '#{tube_position}'."
    raise StandardError, error_message
  end

  # Finds the tube purpose based on the provided UUID, using a cached hash to avoid multiple queries.
  #
  # This method checks a hash of saved purposes to see if the tube purpose with the specified UUID
  # has already been fetched. If it has, the cached purpose is returned. If it has not, the method
  # fetches the tube purpose from the database, caches it in the hash, and then returns it.
  #
  # @param [String] uuid The UUID of the tube purpose to be found.
  #
  # @raise [StandardError] if the tube purpose with the specified UUID is not found.
  #
  # @return [Tube::Purpose] The found Tube::Purpose object.
  def find_tube_purpose(uuid)
    # check a hash of saved purposes to avoid multiple queries
    @tube_purposes[uuid] ||= fetch_tube_purpose(uuid)
  end

  # Fetches the tube purpose based on the provided UUID.
  #
  # This method searches for a Tube::Purpose record with the specified UUID.
  # If a matching record is found, it is cached in the @tube_purposes hash to avoid multiple queries
  # and then returned. If no matching record is found, a StandardError is raised with an appropriate error message.
  #
  # @param [String] uuid The UUID of the tube purpose to be found.
  #
  # @raise [StandardError] if the tube purpose with the specified UUID is not found.
  #
  # @return [Purpose] The found Purpose object.
  def fetch_tube_purpose(uuid)
    tube_purpose = Tube::Purpose.with_uuid(uuid).first
    if tube_purpose
      # save the found purpose to avoid multiple queries
      @tube_purposes[uuid] = tube_purpose
      return tube_purpose
    end

    error_message = "The tube purpose with UUID '#{uuid}' was not found."
    raise StandardError, error_message
  end

  # Inherited from AssetCreation
  def record_creation_of_children
    # Not generating creation events for this labware
  end
end

# rubocop:enable Metrics/ClassLength
