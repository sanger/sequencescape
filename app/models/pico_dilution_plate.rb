class PicoDilutionPlate < DilutionPlate
  # @@per_page is set to a "highish" number so that the first page
  # sent to PicoGreen is likely to hold all the rececent PicoDilutionPlates
  @@per_page = 5000
  self.prefix = "PD"

  def self.index_to_hash(pico_dilutions)
    pico_dilutions.map{ |pico_dilution| pico_dilution.to_hash }
  end

  def study_name
    study.try(:name) || ""
  end

  def to_hash
    {:pico_dilution => {
        :child_barcodes => children.map{ |plate| plate.barcode_and_created_at_hash }
      }.merge(barcode_and_created_at_hash),
        :study_name => study_name
    }
  end

end
