Before('@plate_volume') do |scenario|
  PlateVolume.process_all_volume_check_files
end
