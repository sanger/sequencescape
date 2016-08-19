class LibPoolNormTubeGenerator

  include ActiveModel::Validations

  attr_accessor :plate
  attr_reader :user

  validates_presence_of :plate, :user

  validate :check_state, :check_plate_purpose, if: Proc.new { |p| p.present? }
  
  def initialize(barcode, user)
    self.plate = barcode
    @user = user
  end

  def transfer_template
    @transfer_template ||= TransferTemplate.find_by_name("Transfer from tube to tube by submission")
  end

  def plate=(barcode)
    @plate = Plate.find_from_machine_barcode(barcode)
  end

  def lib_pool_tubes
    plate.wells.map(&:requests).flatten.select do |r|
      r.request_type.key=='Illumina_Lib_PCR_XP_Lib_Pool'
    end.map(&:target_asset).uniq
  end

  def destination_tubes
    @destination_tubes ||= []
  end

  def create!
    lib_pool_tubes.each do |tube|
      pass_and_complete(create_lib_pool_norm_tube(tube))
    end
  end

private

  def create_lib_pool_norm_tube(tube)
    destination_tube = transfer_template.create!(user: user, source: tube).destination
    destination_tubes << destination_tube
    destination_tube
  end

  def pass_and_complete(tube)
    unless tube.state == "qc_complete"
      StateChange.create(user: user, target: tube, target_state: "passed")
      StateChange.create(user: user, target: tube, target_state: "qc_complete")
    end
  end

  def check_state
    errors.add(:plate, "should be qc completed") unless plate.state == "qc_complete"
  end

  def check_plate_purpose
    errors.add(:plate, "should be of type Lib PCR-XP") unless plate.plate_purpose.name == "Lib PCR-XP"
  end
end