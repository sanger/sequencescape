num_pico_plates = PicoDilutionPlate.count

stock_plates = Plate.find(:all, :conditions => "sti_type = 'Plate'", :limit => num_pico_plates)
count = 0
PicoDilutionPlate.all.each do |pico_plate|
  AssetLink.connect(stock_plates[count],pico_plate)
  count = count +1
end

