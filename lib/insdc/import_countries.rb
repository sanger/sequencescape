# frozen_string_literal: true

require 'rexml/document'

# Handles the download and import of permitted country fields from the ENA
class Insdc::ImportCountries
  FILE_ROOT = Rails.root.join('data/ena_sample_checklists')
  FIELD_NAME = 'geographic location (country and/or sea)'
  XPATH = "//FIELD//LABEL[text() = '#{FIELD_NAME}']/following-sibling::FIELD_TYPE//TEXT_VALUE//VALUE".freeze

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

    existing_valid_countries = Insdc::Country.valid_state.pluck(:name)
    existing_invalid_countries = Insdc::Country.invalid_state.pluck(:name)
    existing_countries = Insdc::Country.pluck(:name)

    existing_countries_to_mark_valid = countries_to_import & existing_invalid_countries
    existing_countries_to_mark_invalid = existing_valid_countries - countries_to_import
    new_countries_to_add = countries_to_import - existing_countries

    mark_as_valid(existing_countries_to_mark_valid)
    mark_as_invalid(existing_countries_to_mark_invalid)
    add_countries(new_countries_to_add)

    Rails.logger.info { "#{existing_countries_to_mark_valid.size} existing countries marked as valid" }
    Rails.logger.info { "#{existing_countries_to_mark_invalid.size} existing countries marked as invalid" }
    Rails.logger.info { "#{new_countries_to_add.size} new countries added" }
  end

  private

  def mark_as_valid(countries_to_mark)
    Insdc::Country.where(name: countries_to_mark).find_each(&:valid!)
  end

  def mark_as_invalid(countries_to_mark)
    Insdc::Country.where(name: countries_to_mark).find_each(&:invalid!)
  end

  def add_countries(new_countries_to_add)
    Insdc::Country.import(new_countries_to_add.map do |name|
      { name: name, sort_priority: priority_for(name), validation_state: :valid }
    end)
  end

  def priority_for(name)
    @priorities.fetch(name, 0)
  end

  def xml
    File.open(file_name) { |file| REXML::Document.new(file) }
  end

  def countries_to_import
    @countries_to_import ||= xml.root.get_elements(XPATH).map(&:text)
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
