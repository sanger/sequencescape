class StockStamper

  include ActiveModel::Model

  attr_accessor :user, :source_plate, :source_plate_type, :destination_plate, :destination_plate_type, :destination_plate_maximum_volume, :overage

  validates_presence_of :source_plate_type, :destination_plate_type, :destination_plate_maximum_volume, :overage

  validates :source_plate, presence: { message: 'barcode invalid' }
  validates :destination_plate, presence: { message: 'barcode invalid' }
  validates :user, presence: { message: 'barcode invalid' }
  validate :plates_barcodes_should_be_identical

  def generate_tecan_gwl_file_as_text
    Sanger::Robots::Tecan::Generator.mapping(generate_tecan_data, 0)
  end

  def generate_tecan_data
    source_barcode = "#{source_plate.barcode_for_tecan}_s"
    destination_barcode = "#{source_plate.barcode_for_tecan}_d"
    data_object = {
      "user" => user.login,
      "time" => Time.now,
      "source" => {
        source_barcode => { "name" => source_plate_type.tr('_', "\s"), "plate_size" => source_plate.size }
      },
      "destination" => {
        destination_barcode => {
          "name" => destination_plate_type.tr('_', "\s"),
          "plate_size" => source_plate.size,
          "mapping" => []
        }
      }
    }
    source_plate.wells.each do |well|
      if well.get_current_volume
        data_object["destination"][destination_barcode]["mapping"] << {
          "src_well"  => [source_barcode, well.map.description],
          "dst_well"  => well.map.description,
          "volume"    => volume(well),
          "buffer_volume" => well.get_buffer_volume
        }
      end
    end
    data_object
  end

  def volume(well)
    [well.get_current_volume*overage.to_f, destination_plate_maximum_volume.to_f].min
  end

  def create_asset_audit_event
    AssetAudit.create(asset_id: source_plate.id, key: 'stamping_of_stock', message: "Process 'Stamping of stock' performed", created_by: user.login)
  end

  def source_plate=(source_plate)
    @source_plate = Plate.find_by(barcode: Barcode.number_to_human(source_plate))
  end

  def destination_plate=(destination_plate)
    @destination_plate = Plate.find_by(barcode: Barcode.number_to_human(destination_plate))
  end

  def user=(user)
    @user = User.find_by(barcode: Barcode.barcode_to_human!(user, 'ID')) if User.valid_barcode?(user)
  end

  def plates_barcodes_should_be_identical
    return unless source_plate.present? && destination_plate.present?
    errors.add(:plates_barcodes, "are not identical") unless source_plate.ean13_barcode == destination_plate.ean13_barcode
  end

end