# frozen_string_literal: true

def local_study_fields(xml)
  doc = Nokogiri::XML(xml)
  {
    title: doc.at_xpath('//STUDY_TITLE')&.text,
    description: doc.at_xpath('//STUDY_DESCRIPTION')&.text
  }
end

def remote_drop_box_study_fields(xml)
  doc = Nokogiri::XML(xml)
  {
    title: doc.at_xpath('//PROJECT/TITLE')&.text,
    description: doc.at_xpath('//PROJECT/DESCRIPTION')&.text
  }
end

def fetch_sc_study_xml(study)
  acc_study = Accessionable::Study.new(study)
  acc_study.xml
end

def fetch_drop_box_study_xml(accession_number)
  fetch_drop_box_xml('projects', accession_number)
end

def fetch_drop_box_sample_xml(accession_number)
  fetch_drop_box_xml('samples', accession_number)
end

def fetch_drop_box_xml(data_type, accession_number)
  drop_box_url = configatron.accession.drop_box_url!
  drop_box_url += '/' unless drop_box_url.end_with?('/')
  ega_options = configatron.accession.ega!.to_hash
  url = URI.join(drop_box_url, "#{data_type}/", accession_number).to_s
  rc = RestClient::Resource.new(url, ega_options)
  response = rc.get
  response.body.to_s
end

def fetch_browser_xml(accession_number)
  browser_url = configatron.accession.browser_url!
  browser_url += '/' unless browser_url.end_with?('/')
  ena_options = configatron.accession.ena!.to_hash
  url = URI.join(browser_url, accession_number).to_s
  rc = RestClient::Resource.new(url, ena_options)
  response = rc.get
  response.body.to_s
end

def remote_browser_sample_fields(xml)
  doc = Nokogiri::XML(xml)
  result = {
    taxon_id: doc.at_xpath('//SAMPLE/SAMPLE_NAME/TAXON_ID')&.text,
    common_name: doc.at_xpath('//SAMPLE/SAMPLE_NAME/SCIENTIFIC_NAME')&.text
  }
  doc.xpath('//SAMPLE/SAMPLE_ATTRIBUTES/SAMPLE_ATTRIBUTE').each do |attr|
    tag = attr.at_xpath('TAG')&.text
    tag = tag.downcase unless tag.start_with?('ArrayExpress')
    value = attr.at_xpath('VALUE')&.text
    result[tag.to_sym] = value
  end
  result
end

def remote_drop_box_sample_fields(xml) # rubocop:disable Metrics/AbcSize
  doc = Nokogiri::XML(xml)
  result = {
    taxon_id: doc.at_xpath('//SAMPLE/SAMPLE_NAME/TAXON_ID')&.text,
    common_name: doc.at_xpath('//SAMPLE/SAMPLE_NAME/SCIENTIFIC_NAME')&.text
  }
  doc.xpath('//SAMPLE/SAMPLE_ATTRIBUTES/SAMPLE_ATTRIBUTE').each do |attr|
    tag = attr.at_xpath('TAG')&.text
    tag = tag.downcase unless tag.start_with?('ArrayExpress')
    value = attr.at_xpath('VALUE')&.text
    result[tag.to_sym] = value
  end
  result
end

def remote_browser_study_fields(xml)
  doc = Nokogiri::XML(xml)
  {
    title: doc.at_xpath('//STUDY_TITLE')&.text,
    description: doc.at_xpath('//STUDY_DESCRIPTION')&.text
  }
end

def print_differences(local, remote)
  local.each do |key, value|
    remote_value = remote[key] || ''
    next unless value != remote_value

    puts "SC:  #{key}=#{value}"
    puts "EBI: #{key}=#{remote_value}"
  end
end

def fetch_sc_sample_xml(sample)
  acc_sample = Accessionable::Sample.new(sample)
  acc_sample.xml
end

def local_sample_fields(xml)
  doc = Nokogiri::XML(xml)
  result = {
    common_name: doc.at_xpath('//SAMPLE/SAMPLE_NAME/COMMON_NAME')&.text,
    taxon_id: doc.at_xpath('//SAMPLE/SAMPLE_NAME/TAXON_ID')&.text
  }
  doc.xpath('//SAMPLE/SAMPLE_ATTRIBUTES/SAMPLE_ATTRIBUTE').each do |attr|
    tag = attr.at_xpath('TAG')&.text
    value = attr.at_xpath('VALUE')&.text
    value = '' if value == 'not provided'
    result[tag.to_sym] = value
  end
  result
end

def process_sample(sample) # rubocop:disable Metrics/MethodLength
  puts "sample_id=#{sample.id}, ebi_accession_number=#{sample.ebi_accession_number}"
  xml = fetch_sc_sample_xml(sample)
  local = local_sample_fields(xml)
  # puts xml
  # puts
  # puts local
  # puts

  remote = if sample.ebi_accession_number.start_with?('EGA')
    xml = fetch_drop_box_sample_xml(sample.ebi_accession_number)
    remote_drop_box_sample_fields(xml)
  else
    xml = fetch_browser_xml(sample.ebi_accession_number)
    remote_browser_sample_fields(xml)
  end
  # puts xml
  # puts
  # puts remote
  # puts
  print_differences(local, remote)
end

namespace :ebi do
  desc 'Check study data uploaded to the EBI EGA & ENA databases'
  task :check_studies, [:study_ids] => :environment do
    study_ids = (ENV['study_ids'] || '').split(',').reject(&:empty?)
    if study_ids.empty?
      puts 'Please provide at least one study_id (comma-separated if multiple).'
      puts <<~USAGE
        Usage: bundle exec rake ebi:check_studies study_ids=<study_id>,...
        Example: bundle exec rake ebi:check_studies study_ids=123,456
      USAGE
      exit 1
    end

    study_ids.each do |study_id|
      study = Study.find_by(id: study_id)
      puts "study_id=#{study_id}, ebi_accession_number=#{study.ebi_accession_number}"
      xml = fetch_sc_study_xml(study)
      local = local_study_fields(xml)

      remote = if study.ebi_accession_number.start_with?('EGA')
        xml = fetch_drop_box_study_xml(study.ebi_accession_number)
        remote_drop_box_study_fields(xml)
      else
        xml = fetch_browser_xml(study.ebi_accession_number)
        remote_browser_study_fields(xml)
      end

      print_differences(local, remote)
    end
  end

  desc 'Check sample data uploaded to the EBI EGA & ENA databases'
  task :check_samples, %i[study_ids sample_ids] => :environment do
    study_ids = (ENV['study_ids'] || '').split(',').reject(&:empty?)
    sample_ids = (ENV['sample_ids'] || '').split(',').reject(&:empty?)
    if study_ids.empty? && sample_ids.empty?
      puts 'Please provide at least one study_id or sample_id (comma-separated if multiple).'
      puts <<~USAGE
        Usage: bundle exec rake ebi:check_samples study_ids=<study_id>,... sample_ids=<sample_id>,...
        Example: bundle exec rake ebi:check_samples study_ids=123,456
        Example: bundle exec rake ebi:check_samples sample_ids=789,1011
      USAGE
      exit 1
    end

    puts 'Processing study_ids' if study_ids.any?
    study_ids.each do |study_id|
      study = Study.find_by(id: study_id)
      puts "study_id=#{study_id}, ebi_accession_number=#{study.ebi_accession_number}"
      study.samples.each do |sample|
        process_sample(sample)
      end
    end

    puts 'Processing sample_ids' if sample_ids.any?
    sample_ids.each do |sample_id|
      sample = Sample.find_by(id: sample_id)
      study = sample.studies.first
      puts "study_id=#{study.id}, ebi_accession_number=#{study.ebi_accession_number}"
      process_sample(sample)
    end
  end
end
