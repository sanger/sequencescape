
Before('@plate_volume') do |_scenario|
  PlateVolume.process_all_volume_check_files
end
