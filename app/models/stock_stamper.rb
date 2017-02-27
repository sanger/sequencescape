class StockStamper
  include ActiveModel::Model

  attr_accessor :user, :user_barcode, :plate, :plate_type, :source_plate_barcode, :source_plate_type_name, :destination_plate_barcode, :destination_plate_type_name, :overage, :file_content

  validates_presence_of :user_barcode, :source_plate_barcode, :source_plate_type_name, :destination_plate_barcode, :destination_plate_type_name, :overage

  validates :plate, presence: { message: 'is not registered in sequencescape' }, if: 'destination_plate_barcode.present?'
  validates :plate_type, presence: { message: 'is not registered in sequencescape' }, if: 'destination_plate_type_name.present?'
  validates :user, presence: { message: 'is not registered in sequencescape' }, if: 'user_barcode.present?'
  validate :plates_barcodes_should_be_identical

  def initialize(attributes = { overage: 1.2 })
    self.plate = attributes[:destination_plate_barcode]
    self.plate_type = attributes[:destination_plate_type_name]
    self.user = attributes[:user_barcode]
    super
  end

  def generate_tecan_gwl_file_as_text
    @file_content = Sanger::Robots::Tecan::Generator.mapping(generate_tecan_data, 0)
  end

  def generate_tecan_data
    source_barcode = "#{plate.barcode_for_tecan}_s"
    destination_barcode = "#{plate.barcode_for_tecan}_d"
    data_object = {
      'user' => user.login,
      'time' => Time.now,
      'source' => {
        source_barcode => { 'name' => source_plate_type_name.tr('_', "\s"), 'plate_size' => plate.size }
      },
      'destination' => {
        destination_barcode => {
          'name' => destination_plate_type_name.tr('_', "\s"),
          'plate_size' => plate.size,
          'mapping' => []
        }
      }
    }
    plate.wells.each do |well|
      next unless well.get_current_volume
      data_object['destination'][destination_barcode]['mapping'] << {
        'src_well'  => [source_barcode, well.map.description],
        'dst_well'  => well.map.description,
        'volume'    => volume(well),
        'buffer_volume' => well.get_buffer_volume
      }
    end
    data_object
  end

  def create_asset_audit_event
    AssetAudit.create(asset_id: plate.id, key: 'stamping_of_stock', message: "Process 'Stamping of stock' performed", created_by: user.login)
  end

  private

  def volume(well)
    [well.get_current_volume * overage.to_f, plate_type.maximum_volume.to_f].min
  end

  def plate=(plate)
    @plate = Plate.find_by(barcode: Barcode.number_to_human(plate))
  end

  def plate_type=(plate_type)
    @plate_type = PlateType.find_by(name: plate_type)
  end

  def user=(user)
    @user = User.find_by(barcode: Barcode.barcode_to_human!(user, 'ID')) if User.valid_barcode?(user)
  end

  def plates_barcodes_should_be_identical
    return unless source_plate_barcode.present? && destination_plate_barcode.present?
    errors.add(:plates_barcodes, 'are not identical') unless source_plate_barcode == destination_plate_barcode
  end
end
