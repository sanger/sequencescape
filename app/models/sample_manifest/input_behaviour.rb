require 'linefeed_fix'
require 'csv'
module SampleManifest::InputBehaviour
  module ClassMethods
    def find_sample_manifest_from_uploaded_spreadsheet(spreadsheet_file)
      csv        = CSV.parse(LinefeedFix.scrub!(spreadsheet_file.read))
      column_map = compute_column_map(csv[spreadsheet_header_row])

      spreadsheet_offset.upto(csv.size - 1) do |n|
        sanger_sample_id = SampleManifest.read_column_by_name(csv, n, 'SANGER SAMPLE ID', column_map)
        next if sanger_sample_id.blank?

        sample = SampleManifest.find_or_create_sample(sanger_sample_id) or next
        return sample.sample_manifest
      end
      nil
    end

    def find_or_create_sample(sanger_sample_id)
      sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
      sample.present? ? sample : create_sample(sanger_sample_id)
    end

    def create_sample(sanger_sample_id)
      manifest_asset = SampleManifestAsset.find_by(sanger_sample_id: sanger_sample_id)
      if manifest_asset.present?
        manifest_asset.sample_manifest.create_sample_and_aliquot(sanger_sample_id, manifest_asset.asset)
      else
        raise StandardError, "Cannot find sample manifest for Sanger ID: #{sanger_sample_id}"
      end
    end

    def read_column_by_name(csv, row, name, column_map, default_value = nil)
      col = column_map[name]
      return default_value unless col

      csv[row][col]
    end

    def compute_column_map(names)
      Hash[names.each_with_index.map { |name, index| [name && name.strip.gsub(/\s+/, ' '), index] }].tap do |columns|
        raise StandardError, "No 'SANGER SAMPLE ID' column in #{columns.keys.inspect}" unless columns.key?('SANGER SAMPLE ID')
      end
    end
  end

  def self.included(base)
    base.class_eval do
      include ManifestUtil
      extend ClassMethods

      # Ensure that we can override previous manifest information when required
      extend ValidationStateGuard
      validation_guard(:override_previous_manifest)

      # Ensure that we can update the samples of a manifest
      has_many :samples
      accepts_nested_attributes_for :samples
      alias_method(:update_without_sample_manifest!, :update!)
      alias_method(:update!, :update_with_sample_manifest!)

      # Can be removed once the initial changes have gone live.
      # Ensures code remains backwards compatible for existing jobs.
      alias_method :process_without_delay, :process
    end
  end

  def convert_yes_no_to_boolean(value)
    !!(value && value.match(/Y/i))
  end
  private :convert_yes_no_to_boolean

  def clean_up_value(value)
    return '' if value.nil?

    value.strip
  end
  private :clean_up_value

  def clean_up_sheet(csv)
    # Clean up CSV
    0.upto(csv.size - 1) do |row|
      0.upto(csv[row].size) do |col|
        csv[row][col] = clean_up_value(csv[row][col])
      end
    end
    csv
  end
  private :clean_up_sheet

  def strip_non_word_characters(value)
    return '' if value.nil?

    value.gsub(/[^:alnum:]+/, '')
  end
  private :strip_non_word_characters

  InvalidManifest = Class.new(StandardError)

  def get_headers(csv)
    filter_end_of_header(csv[spreadsheet_header_row]).map do |header|
      h = header.gsub(/\s+/, ' ')
      SampleManifest::Headers.renamed(h)
    end
  end

  def each_csv_row
    csv = CSV.parse(LinefeedFix.scrub!(uploaded.current_data))
    clean_up_sheet(csv)

    headers = get_headers(csv)

    headers.each_with_index.map do |name, _index|
      "Header '#{name}' not recognised!" unless name.blank? || SampleManifest::Headers.valid?(name)
    end.compact.tap do |headers_with_errors|
      raise InvalidManifest, headers_with_errors unless headers_with_errors.empty?
    end

    column_map = SampleManifest.compute_column_map(headers)
    spreadsheet_offset.upto(csv.size - 1) do |row|
      yield(Hash[headers.each_with_index.map { |header, column| [header, csv[row][column]] }])
    end
  rescue CSV::MalformedCSVError => exception
    raise InvalidManifest, "Invalid CSV file, did you upload an Excel file by accident? - #{exception.message}"
  end
  private :each_csv_row

  def process(user_updating_manifest, override_sample_information = false)
    Delayed::Job.enqueue SampleManifest::ProcessJob.new(id, user_updating_manifest.id, override_sample_information)
  end

  # Always allow 'empty' samples to be updated, but non-empty samples need to have the override checkbox set for an update to occur
  def process_job(user_updating_manifest, override_sample_information = false)
    start!

    samples_to_updated_attributes, sample_errors = [], []
    each_csv_row do |row|
      sanger_sample_id = row['SANGER SAMPLE ID']
      next if sanger_sample_id.blank?

      # Sanity check that the sample being updated is in the same container that it was defined against.
      #
      # NOTE: Do not include the primary_receptacle here as it will cause the wrong one to be loaded!
      sample = samples.find_by(sanger_sample_id: sanger_sample_id)

      errors = false

      if sample.nil?
        sample_errors.push("Sample #{sanger_sample_id} does not appear to be part of this manifest")
        errors = true
      elsif sample.primary_receptacle.nil?
        sample_errors.push("Sample #{sanger_sample_id} appears to not have a receptacle defined! Contact PSD")
        errors = true
      else
        validate_sample_container(sample, row) do |message|
          sample_errors.push(message)
          errors = true
        end
        validate_specialized_fields(sample, row) do |message|
          sample_errors.push(message)
          errors = true
        end
      end
      next if errors

      metadata = Hash[
        SampleManifest::Headers::METADATA_ATTRIBUTES_TO_CSV_COLUMNS.map do |attribute, csv_column|
          [attribute, row[csv_column]]
        end
      ].merge(
        is_resubmitted: convert_yes_no_to_boolean(row['IS RE-SUBMITTED SAMPLE?'])
      )

      samples_to_updated_attributes.push([
        sample.id, {
          id: sample.id,
          sanger_sample_id: sanger_sample_id,
          control: convert_yes_no_to_boolean(row['IS SAMPLE A CONTROL?']),
          sample_metadata_attributes: metadata.delete_if { |_, v| v.nil? }
        }.merge(specialized_fields(row))
      ])
    end

    return fail_with_errors!(sample_errors) unless sample_errors.empty?

    ActiveRecord::Base.transaction do
      update!({
                override_previous_manifest: override_sample_information,
                samples_attributes: samples_to_updated_attributes.map(&:last)
              }, user_updating_manifest)

      core_behaviour.updated_by!(user_updating_manifest, samples_to_updated_attributes.map(&:first).compact)

      samples_to_be_broadcasted = samples.each_with_object([]) do |sample, array|
        array << sample.id if sample.changed_by_manifest?
      end

      updated_broadcast_event(user_updating_manifest, samples_to_be_broadcasted) if samples_to_be_broadcasted.present?
    end

    self.last_errors = nil
    finished!
  rescue ActiveRecord::RecordInvalid => exception
    errors.add(:base, exception.message)
    fail_with_errors!(errors.full_messages)
  rescue ActiveRecord::StatementInvalid => exception
    # This tends to get raised in cases of character encoding issues. If we don't
    # handle it here, then the delayed job tires to handle it, but just ends up
    # generating its own invalid SQL. This results in the delayed job dying,
    # and needs manual intervention to recover. This is intended merely as a fix
    # for the delayed job worker death, and not the underlying issue.
    # https://github.com/collectiveidea/delayed_job/issues/774
    # It is possible to monkey patch with the solution suggested by philister
    scrubbed_message = exception.message.encode('ISO-8859-1', invalid: :replace)
    fail_with_errors!(["Failed to update information in database: #{scrubbed_message}"])
  rescue InvalidManifest => exception
    fail_with_errors!(Array(exception.message).flatten)
  end

  def fail_with_errors!(errors)
    reload
    self.last_errors = errors
    fail!
  end
  private :fail_with_errors!

  def ensure_samples_are_being_updated_by_manifest(attributes, user)
    attributes.fetch(:samples_attributes, []).each do |sample_attributes|
      sample_attributes.merge!(
        updating_from_manifest: true,
        can_rename_sample: true,
        user_performing_manifest_update: user,
        override_previous_manifest: (override_previous_manifest? || attributes[:override_previous_manifest])
      )
      sample_attributes[:sample_metadata_attributes].delete_if { |_, v| v.nil? }
      sample_attributes[:sample_metadata_attributes][:updating_from_manifest] = true
    end
  end
  private :ensure_samples_are_being_updated_by_manifest

  def update_with_sample_manifest!(attributes, user = nil)
    ActiveRecord::Base.transaction do
      ensure_samples_are_being_updated_by_manifest(attributes, user)
      update_without_sample_manifest!(attributes.with_indifferent_access)
    end
  end

  # updates the manifest barcode list e.g. after applying a foreign barcode
  def update_barcodes
    self.barcodes = labware.map(&:human_barcode)
    save!
  end
end
