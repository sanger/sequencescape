require 'csv'
require 'logger'

ActiveRecord::Base.logger = nil
logger = Logger.new("sample_ids_log.log")
data = CSV.parse(File.read("data/data_fixes/root_sample_ids.csv"), headers: true)
failed_ids = Array.new()
success_ids = Array.new()

data.each_with_index do |row, index|
    if index % 1000 == 0
        puts "."
    end
    samples = Sample::Metadata.where("sample_description" => row["original_root_sample_id"])
    if samples != []
        samples.each do |sample|
            logger.debug("updating row with ID: #{id}, sample ID: #{sample.sample_id}, root_sample ID: #{sample.sample_description}")
            sample.sample_description = row["root_sample_id"]
            saved = sample.save
            if saved
                success_ids << "Successfully saved new Root Sample ID for row with ID: #{sample.sample_id}"
            else
                failed_ids << "Could not save new Root Sample ID for row with ID: #{sample.id}"
            end
        end
    else
        failed_ids << "No matching result for Root Sample ID: #{row["original_root_sample_id"]}"
    end
end

logger.info("Successes: #{success_ids.length}")
logger.debug("Updated IDs: #{success_ids}")
logger.info("Failures: #{failed_ids.length}")
logger.debug("Couldn't find/update IDs: #{failed_ids}")
