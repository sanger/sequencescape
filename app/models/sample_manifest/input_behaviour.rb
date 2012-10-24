module SampleManifest::InputBehaviour
  module ClassMethods
    def find_sample_manifest_from_uploaded_spreadsheet(spreadsheet_file)
      csv        = FasterCSV.parse(spreadsheet_file.read)
      column_map = compute_column_map(csv[spreadsheet_header_row])

      spreadsheet_offset.upto(csv.size-1) do |n|
        sanger_sample_id = SampleManifest.read_column_by_name(csv, n, 'SANGER SAMPLE ID', column_map)
        next if sanger_sample_id.blank?
        sample           = Sample.find_by_sanger_sample_id(sanger_sample_id) or next
        return sample.sample_manifest
      end
      nil
    end

    def read_column_by_name(csv, row, name, column_map, default_value=nil)
      col = column_map[name]
      return default_value unless col
      return csv[row][col]
    end

    def compute_column_map(names)
      Hash[names.each_with_index.map  { |name, index| [name && name.strip.gsub(/\s+/," "), index]}].tap do |columns|
        raise StandardError, "No 'SANGER SAMPLE ID' column in #{columns.keys.inspect}" unless columns.key?('SANGER SAMPLE ID')
      end
    end
  end

  module SampleUpdating
    module MetadataRules
      def self.included(base)
        base.class_eval do
          extend ValidationStateGuard
          validation_guard(:updating_from_manifest)

          # These need to be checked when updating from a sample manifest.  We need to be able to display
          # the sample ID so this can't be done with validates_presence_of
          validates_each(:volume, :concentration, :if => :updating_from_manifest?) do |record, attr, value|
            record.errors.add_on_blank(attr, "can't be blank for #{record.sample.sanger_sample_id}")
          end
        end
      end
    end

    def self.included(base)
      base.class_eval do
        extend ValidationStateGuard

        # You cannot create a sample through updating the sample manifest
        validates_each(:id, :on => :create, :if => :updating_from_manifest?) do |record, attr, value|
          record.errors.add_to_base("Could not find sample #{record.sanger_sample_id}") if value.blank?
        end

        # We ensure that certain fields are updated properly if we're doing so through a manifest
        before_validation(:if => :updating_from_manifest?) do |record|
          if record.sample_supplier_name_empty?(record.sample_metadata.supplier_name)
            record.reset_all_attributes_to_previous_values
            record.empty_supplier_sample_name = true
            record.generate_no_update_event
          else
            record.empty_supplier_sample_name = false
            record.updated_by_manifest        = true
          end
        end

        # If the sample has already been updated by a manifest, and we're not overriding it
        # then we should reset the sample information
        before_validation(:if => :updating_from_manifest?) do |record|
          record.reset_all_attributes_to_previous_values unless record.can_override_previous_manifest?
        end

        # We need to record any updates if we're working through a manifest update
        attr_accessor :user_performing_manifest_update
        after_save(:handle_update_event, :if => :updating_from_manifest?)

        # The validation guards need declaring last so that they are reset after all of the after_save
        # callbacks that may need them are executed.
        validation_guard(:updating_from_manifest)
        validation_guard(:override_previous_manifest)
      end

      # Modify the metadata so that it does the right checks when we are updating from a manifest
      base::Metadata.class_eval do
        include MetadataRules
      end
    end

    def handle_update_event
      events.updated_using_sample_manifest!(user_performing_manifest_update) unless @generate_no_update_event
      user_performing_manifest_update = nil
    end
    private :handle_update_event

    def generate_no_update_event
      @generate_no_update_event = true
    end

    def can_override_previous_manifest?
      # Have to use the previous value of 'updated_by_manifest' here as it may have been changed by
      # the current update.
      not self.updated_by_manifest_was or override_previous_manifest?
    end

    # Resets all of the attributes to their previous values
    def reset_all_attributes_to_previous_values
      reload unless new_record?
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      handle_asynchronously :process

      # Ensure that we can override previous manifest information when required
      extend ValidationStateGuard
      validation_guard(:override_previous_manifest)

      # Ensure that we can update the samples of a manifest
      has_many :samples
      accepts_nested_attributes_for :samples
      alias_method_chain(:update_attributes!, :sample_manifest)
    end
  end

  def convert_yes_no_to_boolean(value)
    !!(value && value.match(/Y/i))
  end
  private :convert_yes_no_to_boolean

  def clean_up_value(value)
    return "" if value.nil?
    value.strip
  end
  private :clean_up_value

  def clean_up_sheet(csv)
    # Clean up CSV
    0.upto(csv.size-1) do |row|
      0.upto(csv[row].size) do |col|
        csv[row][col] = clean_up_value(csv[row][col])
      end
    end
    csv
  end
  private :clean_up_sheet

  def strip_non_word_characters(value)
    return "" if value.nil?
    value.gsub(/[^:alnum:]+/, '')
  end
  private :strip_non_word_characters

  METADATA_ATTRIBUTES_TO_CSV_COLUMNS = {
    :cohort                      => 'COHORT',
    :gender                      => 'GENDER',
    :father                      => 'FATHER (optional)',
    :mother                      => 'MOTHER (optional)',
    :sibling                     => 'SIBLING (optional)',
    :country_of_origin           => 'COUNTRY OF ORIGIN',
    :geographical_region         => 'GEOGRAPHICAL REGION',
    :ethnicity                   => 'ETHNICITY',
    :dna_source                  => 'DNA SOURCE',
    :date_of_sample_collection   => 'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',
    :date_of_sample_extraction   => 'DATE OF DNA EXTRACTION (MM/YY or YYYY only)',
    :sample_extraction_method    => 'DNA EXTRACTION METHOD',
    :sample_purified             => 'SAMPLE PURIFIED?',
    :purification_method         => 'PURIFICATION METHOD',
    :concentration               => "CONC. (ng/ul)",
    :concentration_determined_by => 'CONCENTRATION DETERMINED BY',
    :sample_taxon_id             => 'TAXON ID',
    :sample_description          => 'SAMPLE DESCRIPTION',
    :sample_ebi_accession_number => 'SAMPLE ACCESSION NUMBER (optional)',
    :sample_sra_hold             => 'SAMPLE VISIBILITY',
    :sample_type                 => 'SAMPLE TYPE',
    :volume                      => "VOLUME (ul)",
    :sample_storage_conditions   => 'DNA STORAGE CONDITIONS',
    :supplier_name               => 'SUPPLIER SAMPLE NAME',
    :gc_content                  => 'GC CONTENT',
    :sample_public_name          => 'PUBLIC NAME',
    :sample_common_name          => 'COMMON NAME',
    :sample_strain_att           => 'STRAIN'
  }

  InvalidManifest = Class.new(StandardError)

  def each_csv_row(&block)
    csv = FasterCSV.parse(uploaded.data)
    clean_up_sheet(csv)

    headers = csv[spreadsheet_header_row].map { |header| header.gsub(/\s+/, ' ') }
    headers.each_with_index.map do |name, index|
      "Header '#{name}' should be '#{ColumnMap.fields[index]}'" if not name.blank? and strip_non_word_characters(name) != strip_non_word_characters(ColumnMap.fields[index])
    end.compact.tap do |headers_with_errors|
      raise InvalidManifest, headers_with_errors unless headers_with_errors.empty?
    end

    column_map = SampleManifest.compute_column_map(headers)
    spreadsheet_offset.upto(csv.size-1) do |row|
      yield(Hash[headers.each_with_index.map { |header, column| [ header, csv[row][column] ] }])
    end
  rescue FasterCSV::MalformedCSVError => exception
    raise InvalidManifest, "Invalid CSV file, did you upload an EXCEL file by accident? - #{exception.message}"
  end
  private :each_csv_row

  # Always allow 'empty' samples to be updated, but non-empty samples need to have the override checkbox set for an update to occur
  def process(user_updating_manifest, override_sample_information = false)
    self.start!

    samples_to_updated_attributes, sample_errors = [], []
    each_csv_row do |row|
      sanger_sample_id = row['SANGER SAMPLE ID']
      next if sanger_sample_id.blank?

      # Sanity check that the sample being updated is in the same container that it was defined against.
      #
      # NOTE: Do not include the primary_receptacle here as it will cause the wrong one to be loaded!
      sample = samples.find_by_sanger_sample_id(sanger_sample_id)
      if sample.nil?
        sample_errors.push("Sample #{sanger_sample_id} does not appear to be part of this manifest")
        next
      elsif sample.primary_receptacle.nil?
        sample_errors.push("Sample #{sanger_sample_id} appears to not have a receptacle defined! Contact PSD")
        next
      else
        validate_sample_container(sample, row) do |message|
          sample_errors.push(message)
          next
        end
      end

      metadata = Hash[
        METADATA_ATTRIBUTES_TO_CSV_COLUMNS.map do |attribute, csv_column|
          [ attribute, row[csv_column] ]
        end
      ].merge(
        :is_resubmitted => convert_yes_no_to_boolean(row['IS RE-SUBMITTED SAMPLE?'])
      )

      samples_to_updated_attributes.push([
        sample, {
          :id                         => sample.try(:id),
          :sanger_sample_id           => sanger_sample_id,
          :control                    => convert_yes_no_to_boolean(row['IS SAMPLE A CONTROL?']),
          :sample_metadata_attributes => metadata.delete_if { |_,v| v.nil? }
        }
      ])
    end

    raise InvalidManifest, sample_errors unless sample_errors.empty?

    ActiveRecord::Base.transaction do
      update_attributes!({
        :override_previous_manifest => override_sample_information,
        :samples_attributes         => samples_to_updated_attributes.map(&:last)
      }, user_updating_manifest)
      core_behaviour.updated_by!(user_updating_manifest, samples_to_updated_attributes.map(&:first).compact)
    end

    self.last_errors = nil
    self.finished!
  rescue ActiveRecord::RecordInvalid => exception
    fail_with_errors!(errors.full_messages)
  rescue InvalidManifest => exception
    fail_with_errors!(Array(exception.message).flatten)
  end

  def fail_with_errors!(errors)
    reload
    self.last_errors = errors
    self.fail!
  end
  private :fail_with_errors!

  def ensure_samples_are_being_updated_by_manifest(attributes, user)
    attributes.fetch(:samples_attributes, []).each do |sample_attributes|
      sample_attributes.merge!(
        :updating_from_manifest          => true,
        :can_rename_sample               => true,
        :user_performing_manifest_update => user,
        :override_previous_manifest      => (override_previous_manifest? || attributes[:override_previous_manifest])
      )
      sample_attributes[:sample_metadata_attributes].delete_if { |_,v| v.nil? }
      sample_attributes[:sample_metadata_attributes][:updating_from_manifest] = true
    end
  end
  private :ensure_samples_are_being_updated_by_manifest

  def update_attributes_with_sample_manifest!(attributes, user = nil)
    ensure_samples_are_being_updated_by_manifest(attributes, user)
    update_attributes_without_sample_manifest!(attributes)
  end
end
