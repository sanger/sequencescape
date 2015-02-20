#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
num_pico_plates = PicoDilutionPlate.count

stock_plates = Plate.find(:all, :conditions => "sti_type = 'Plate'", :limit => num_pico_plates)
count = 0
PicoDilutionPlate.all.each do |pico_plate|
  AssetLink.create_edge!(stock_plates[count],pico_plate)
  count = count +1
end

