Given /^the plate with ID (\d+) has attatched QC data with a UUID of "(.*?)"$/ do |id, uuid|
  filename = File.expand_path(File.join(Rails.root, %w{test data example_file.txt}))
  File.open(filename) do |file|
    Plate.find(id).add_qc_information(file)
  end
  set_uuid_for(Plate.find(id).qc_information.last, uuid)
end
