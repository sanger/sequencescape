class Plate::Creator < ApplicationRecord
  PlateCreationError = Class.new(StandardError)

  class PurposeRelationship < ApplicationRecord
    self.table_name = ('plate_creator_purposes')

    belongs_to :plate_purpose
    belongs_to :plate_creator, class_name: 'Plate::Creator'
  end

  class ParentPurposeRelationship < ApplicationRecord
    self.table_name = ('plate_creator_parent_purposes')

    belongs_to :plate_purpose, class_name: 'Purpose'
  end

  self.table_name = 'plate_creators'

  # These are the plate purposes that will be created when this creator is used.
  has_many :plate_creator_purposes, class_name: 'Plate::Creator::PurposeRelationship', dependent: :destroy, foreign_key: :plate_creator_id
  has_many :plate_purposes, through: :plate_creator_purposes

  has_many :parent_purpose_relationships, class_name: 'Plate::Creator::ParentPurposeRelationship', dependent: :destroy, foreign_key: :plate_creator_id
  has_many :parent_plate_purposes, through: :parent_purpose_relationships, source: :plate_purpose

  serialize :valid_options

  attr_reader :created_asset_group

  def created_plates
    @created_plates ||= []
  end

  # Executes the plate creation so that the appropriate child plates are built.
  def execute(source_plate_barcodes, barcode_printer, scanned_user, creator_parameters = nil, should_create_asset_group)
    @created_plates = []
    ActiveRecord::Base.transaction do
      new_plates = create_plates(source_plate_barcodes, scanned_user, creator_parameters)
      return false if new_plates.empty?

      new_plates.group_by(&:plate_purpose).each do |plate_purpose, plates|
        print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                               LabelPrinter::Label::PlateCreator,
                                               plates: plates, plate_purpose: plate_purpose, user_login: scanned_user.login)
        print_job.execute
      end
      if should_create_asset_group == 'Yes'
        ass_g = create_asset_group(created_plates)
        @created_asset_group = ass_g
      end
      true
    end
  end

  def create_plates_from_tube_racks!(tube_racks, barcode_printer, scanned_user, _creator_parameters = nil, should_create_asset_group)
    @created_plates = []
    plate_purpose = plate_purposes.first
    plate_factories = tube_rack_to_plate_factories(tube_racks, plate_purpose)
    unless plate_factories.all?(&:valid?)
      errors = plate_factories.map(&:error_messages)
      raise PlateCreationError, "Plate creation failed with the following errors: #{errors}"
    end

    ActiveRecord::Base.transaction do
      plate_factories.each do |factory|
        factory.save
        add_created_plates(factory.tube_rack, [factory.plate])
      end
    end
    print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                           LabelPrinter::Label::PlateCreator,
                                           plates: created_plates.pluck(:destinations).flatten.compact,
                                           plate_purpose: plate_purpose, user_login: scanned_user.login)

    unless print_job.execute
      raise PlateCreationError, 'Barcode labels failed to print.'
    end

    create_asset_group(created_plates) if should_create_asset_group == 'Yes'

    true
  end

  private

  def create_asset_group(created_plates)
    ass_g = AssetGroup.create!(study: Study.last, name: "asset_group_#{Time.now}")

    created_plates.each do |created_plate_hash|
      destinations = created_plate_hash[:destinations]
      destinations.each do |destination|
        barcode = destination.human_barcode
        plate = Plate.find_by_barcode(barcode)

        plate.wells.each do |well|
          ass_g.assets << well
        end
      end
    end
    ass_g
  end

  def tube_rack_to_plate_factories(tube_racks, plate_purpose)
    tube_racks.map { |rack| ::Heron::Factories::Plate.new(tube_rack: rack, plate_purpose: plate_purpose) }
  end

  def can_create_plates?(source_plate)
    parent_plate_purposes.empty? || parent_plate_purposes.include?(source_plate.purpose)
  end

  def create_plate_without_parent(creator_parameters)
    plate_purposes.map do |purpose|
      plate = purpose.create!
      creator_parameters.set_plate_parameters(plate) unless creator_parameters.nil?
      plate
    end
  end

  def create_plates(source_plate_barcodes, current_user, creator_parameters = nil)
    if source_plate_barcodes.blank?
      # No barcodes have been scanned. This results in empty plates. This behaviour
      # is used in a few circumstances. User comment:
      # bs6: we use it to create 'pico standard' barcodes, as well as 'aliquot' barcodes.
      # The latter is used on the rare occasion that we receive unlabelled samples that
      # we need to record a location for. Not sure there's anything else.
      create_plate_without_parent(creator_parameters).tap do |destinations|
        add_created_plates(nil, destinations)
      end
    else
      # In the majority of cases the users are creating stamps of the provided plates.
      scanned_barcodes = source_plate_barcodes.split(/[\s,]+/)
      raise PlateCreationError, "Scanned plate barcodes in incorrect format: #{source_plate_barcodes.inspect}" if scanned_barcodes.blank?

      # NOTE: Plate barcodes are not unique within certain laboratories.  That means that we cannot do:
      #  plates = Plate.with_barcode(*scanned_barcodes).all(:include => [ :location, { :wells => :aliquots } ])
      # Because then you get multiple matches.  So we take the first match, which is just not right.

      scanned_barcodes.each_with_object([]) do |scanned, plates|
        plate =
          Plate.with_barcode(scanned).eager_load(wells: :aliquots).first or
          raise ActiveRecord::RecordNotFound, "Could not find plate with machine barcode #{scanned.inspect}"

        unless can_create_plates?(plate)
          raise PlateCreationError, "Scanned plate #{scanned} has a purpose #{plate.purpose.name} not valid for creating [#{plate_purposes.map(&:name).join(',')}]"
        end

        destinations = create_child_plates_from(plate, current_user, creator_parameters)
        add_created_plates(plate, destinations)
        plates.concat(destinations)
      end
    end
  end

  def add_created_plates(source, destinations)
    created_plates.push(
      source: source,
      destinations: destinations
    )
  end

  def create_child_plates_from(plate, current_user, creator_parameters)
    stock_well_picker = plate.plate_purpose.stock_plate? ? ->(w) { [w] } : ->(w) { w.stock_wells }
    parent_wells = plate.wells

    plate_purposes.map do |target_plate_purpose|
      target_plate_purpose.create!(:without_wells, barcode: plate.barcode_number) do |child_plate|
        child_plate.size          = plate.size
        child_plate.name          = "#{target_plate_purpose.name} #{child_plate.human_barcode}"
      end.tap do |child_plate|
        child_plate.wells << parent_wells.map do |well|
          well.dup.tap do |child_well|
            child_well.aliquots = well.aliquots.map(&:dup)
            child_well.stock_wells.attach(stock_well_picker.call(well))
          end
        end

        creator_parameters.set_plate_parameters(child_plate, plate) unless creator_parameters.nil?

        AssetLink.create_edge!(plate, child_plate)
        plate.events.create_plate!(target_plate_purpose, child_plate, current_user)
      end
    end
  end
end
