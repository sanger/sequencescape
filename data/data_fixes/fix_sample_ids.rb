require 'csv'
data = CSV.parse(File.read("data/data_fixes/root_sample_ids.csv"), headers: true)
data.each_with_index do |row, index|
    sample = Sample::Metadata.find_by(sample_description: row['original_root_sample_id'])
    if sample
        sample.sample_description = row['root_sample_id']
        sample.save
    end
end

