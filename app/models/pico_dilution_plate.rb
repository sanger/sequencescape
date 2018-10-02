class PicoDilutionPlate < DilutionPlate
  # self.per_page is set to a "highish" number so that the first page
  # sent to PicoGreen is likely to hold all the recent PicoDilutionPlates
  self.per_page = 5000

  def self.index_to_hash(pico_dilutions)
    pico_dilutions.map { |pico_dilution| pico_dilution.to_pico_hash }
  end
end
