# frozen_string_literal: true
class StockStamper
  include ActiveModel::Model

  attr_accessor :user_barcode,
                :source_plate_barcode,
                :source_plate_type_name,
                :destination_plate_barcode,
                :overage,
                :file_content
  attr_reader :destination_plate_type_name, :user_barcode, :user, :plate_type, :plate

  validates :user_barcode,
            :source_plate_barcode,
            :source_plate_type_name,
            :destination_plate_barcode,
            :destination_plate_type_name,
            :overage,
            presence: true

  validates :plate, presence: { message: 'is not registered in Sequencescape' }, if: :destination_plate_barcode?
  validates :plate_type, presence: { message: 'is not registered in Sequencescape' }, if: :destination_plate_type_name?
  validates :user, presence: { message: 'is not registered in Sequencescape' }, if: :user_barcode?
  validate :plates_barcodes_should_be_identical

  def initialize(attributes = { overage: 1.2 })
    super
  end

  def execute
    generate_tecan_gwl_file_as_text
    create_asset_audit_event
    if wells_with_excess.present?
      message[:error] =
        "Required volume exceeds the maximum well volume for well(s) #{wells_with_excess.join(', ')}. " \
        "Maximum well volume #{plate_type.maximum_volume.to_f} will be used in tecan file"
    end
    message[:notice] = 'You can generate the TECAN file and print label now.'
  end

  def generate_tecan_gwl_file_as_text
    picking_data = generate_tecan_data
    layout = Robot::Verification::SourceDestBeds.new.layout_data_object(picking_data)
    @file_content = Robot::Generator::Tecan.new(picking_data: picking_data, layout: layout, total_volume: 0).as_text
  end

  def generate_tecan_data # rubocop:todo Metrics/AbcSize
    source_barcode = "#{plate.machine_barcode}_s"
    destination_barcode = "#{plate.machine_barcode}_d"
    data_object = {
      'user' => user.login,
      'time' => Time.zone.now,
      'source' => {
        source_barcode => {
          'name' => source_plate_type_name.tr('_', "\s"),
          'plate_size' => plate.size
        }
      },
      'destination' => {
        destination_barcode => {
          'name' => destination_plate_type_name.tr('_', "\s"),
          'plate_size' => plate.size,
          'mapping' => []
        }
      }
    }
    plate.wells.without_blank_samples.each do |well|
      next unless well.get_current_volume

      data_object['destination'][destination_barcode]['mapping'] << {
        'src_well' => [source_barcode, well.map.description],
        'dst_well' => well.map.description,
        'volume' => volume(well),
        'buffer_volume' => well.get_buffer_volume
      }
    end
    data_object
  end

  def create_asset_audit_event
    AssetAudit.create(
      asset_id: plate.id,
      key: 'stamping_of_stock',
      message: "Process 'Stamping of stock' performed",
      created_by: user.login
    )
  end

  def message
    @message ||= {}
  end

  def wells_with_excess
    @wells_with_excess ||= []
  end

  def destination_plate_type_name=(type_name)
    @destination_plate_type_name = type_name
    @plate_type = PlateType.find_by(name: type_name)
  end

  def user_barcode=(barcode)
    @user_barcode = barcode
    user = User.find_with_barcode_or_swipecard_code(barcode)
    return if user.nil?

    @user = user
  end

  def destination_plate_barcode=(barcode)
    @destination_plate_barcode = barcode
    @plate = Plate.with_barcode(barcode).first
  end

  private

  def destination_plate_barcode?
    destination_plate_barcode.present?
  end

  def destination_plate_type_name?
    destination_plate_type_name.present?
  end

  def user_barcode?
    user_barcode.present?
  end

  def volume(well) # rubocop:todo Metrics/AbcSize
    if well.get_current_volume * overage.to_f < plate_type.maximum_volume.to_f
      well.get_current_volume * overage.to_f
    else
      wells_with_excess << well.map_description
      plate_type.maximum_volume.to_f
    end
  end

  def plates_barcodes_should_be_identical
    return unless source_plate_barcode.present? && destination_plate_barcode.present?

    errors.add(:plates_barcodes, 'are not identical') unless source_plate_barcode == destination_plate_barcode
  end
end
