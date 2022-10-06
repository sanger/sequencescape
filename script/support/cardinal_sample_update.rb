#!/usr/bin/env ruby

# For each Cardinal sample, fetch its supplier name from the sample manifest
# Use this to back populate the new collected_by attribute on sample metadata

# The below was ran in the ruby console on the server

puts('Getting all Cardinal samples')
component_sample_ids = SampleCompoundComponent.all.map(&:component_sample_id)

puts('Number of samples to update: ', component_sample_ids.count)

number_of_samples_updated = 0
component_sample_ids.map do |sample_id|
  sample = Sample.find(sample_id)
  supplier_name = sample.sample_manifest.supplier_name
  sample.sample_metadata.update!(collected_by: supplier_name)
  number_of_samples_updated += 1
end

puts('Number of samples updated: ', number_of_samples_updated)
