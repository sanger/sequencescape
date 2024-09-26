# frozen_string_literal: true

require 'rexml/document'

# Handles the download and import of permitted country fields from the ENA
class Insdc::ImportCountries
  FILE_ROOT = Rails.root.join('data/ena_sample_checklists')
  FIELD_NAME = 'geographic location (country and/or sea)'
  XPATH = "//FIELD//NAME[text() = '#{FIELD_NAME}']/following-sibling::FIELD_TYPE//TEXT_VALUE//VALUE".freeze

  def initialize(ena_root:, sample_checklist:, priorities: {})
    @ena_root = ena_root
    @sample_checklist = sample_checklist
    @priorities = priorities
  end

  def download(force: false)
    return unless force || file_missing?

    payload = RestClient.get(url).body
    File.write(file_name, payload)
  end

  def import
    no_file_error if file_missing?

    pending_countries = countries_to_import

    # Mark countries as invalid if they aren't on the list
    Insdc::Country.find_each { |country| country.invalid! unless pending_countries.delete(country.name) }

    generate_countries(pending_countries)
  end

  private

  def generate_countries(pending_countries)
    Insdc::Country.import(pending_countries.map { |name| { name: name, sort_priority: priority_for(name) } })
  end

  def priority_for(name)
    @priorities.fetch(name, 0)
  end

  def xml
    File.open(file_name) { |file| REXML::Document.new(file) }
  end

  def countries_to_import
    xml.root.get_elements(XPATH).map(&:text)
  end

  def url
    "#{@ena_root}#{@sample_checklist}"
  end

  def file_missing?
    !File.exist?(file_name)
  end

  def file_name
    "#{FILE_ROOT}/#{@sample_checklist}.xml"
  end

  def no_file_error
    raise StandardError, "Could not find #{file_name}. Please ensure file is downloaded first."
  end
end
