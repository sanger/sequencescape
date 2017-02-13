# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
accession_needed = []
Study.all.each do |study|
  next unless study.data_release_strategy == 'open'
  next unless study.ena_accession_required?
  next if study.samples.nil?

  study.samples.each do |sample|
    if sample.ebi_accession_number
      accession_needed << sample.id
    end
  end
end

app = ActiveResource::Connection.new("http://#{configatron.site_url}")
accession_needed.each do |sample_id|
  sample = Sample.find(sample_id)
  next if sample.nil?
  if sample.ebi_accession_number
    begin
      app.get "/samples/accession/#{sample_id}?api_key=#{configatron.accession_local_key}"
    rescue
    end
  end
end
