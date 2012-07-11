class AddPcrRepeatPlateType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      printer = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate') or raise "Cannot find 96 well plate printer"

      repeat_plate_type = PlatePurpose.create!(
        :name                  => 'ILB_STD_PCRR',
        :cherrypickable_target => false,
        :cherrypick_direction  => IlluminaB::PlatePurposes.plate_direction,
        :barcode_printer_type  => printer
      )

      # It flows from the PRE PCR via a particular request type ...
      prepcr             = PlatePurpose.find_by_name('ILB_STD_PREPCR')                      or raise "Cannot find ILB_STD_PREPCR plate purpose"
      input_request_type = RequestType.find_by_key('Illumina_B_ILB_STD_PREPCR_ILB_STD_PCR') or raise "Cannot find input request type"
      prepcr.child_relationships.create!(:child => repeat_plate_type, :transfer_request_type => input_request_type)

      # ... and into the PCR XP via another
      pcrxp               = PlatePurpose.find_by_name('ILB_STD_PCRXP')                      or raise "Cannot find ILB_STD_PCRXP plate purpose"
      output_request_type = RequestType.find_by_key('Illumina_B_ILB_STD_PCR_ILB_STD_PCRXP') or raise "Cannot find output request type"
      repeat_plate_type.child_relationships.create!(:child => pcrxp, :transfer_request_type => output_request_type)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('ILB_STD_PCRR').destroy
    end
  end
end
