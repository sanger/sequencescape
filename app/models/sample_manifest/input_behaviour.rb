module SampleManifest::InputBehaviour
  module ClassMethods
    def find_sample_manifest_from_uploaded_spreadsheet(spreadsheet_file)
      csv  = FasterCSV.parse(spreadsheet_file.read)
      column_map = compute_column_map(csv[::SampleManifest::SPREADSHEET_HEADER_ROW])

      offset = ::SampleManifest::SPREADSHEET_OFFSET
      offset.upto(csv.size-1) do |n|
        sanger_sample_id = SampleManifest.read_column_by_name(csv, n, 'SANGER SAMPLE ID', column_map)
        next if sanger_sample_id.blank?
        sample = Sample.find_by_sanger_sample_id(sanger_sample_id)
        next if sample.nil?
        return sample.sample_manifest
      end
      nil
    rescue
      nil
    end

    def read_column_by_name(csv, row, name, column_map, default_value=nil)
      col = column_map[name]
      return default_value unless col
      return csv[row][col]
    end

    def compute_column_map(names)
      Hash[names.each_with_index.map  { |name, index| [name && name.strip.gsub(/\s+/," "), index]}]
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      handle_asynchronously :process
    end
  end
  
  RequiredFieldMissing = Class.new(StandardError)
 
  def check_for_required_fields!(row)
    ColumnMap.required_columns.each do  |column_name|
      raise RequiredFieldMissing, "#{column_name} is required for #{row[ColumnMap['SANGER SAMPLE ID']]}" if row[ColumnMap[column_name]].blank?
    end
  end
  private :check_for_required_fields!
  
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

  # Always allow 'empty' samples to be updated, but non-empty samples need to have the override checkbox set for an update to occur
  def process(override_sample_information = false)
    self.start!
    @manifest_errors = []

    begin
      ActiveRecord::Base.transaction do

        csv  = FasterCSV.parse(uploaded.data)
        clean_up_sheet(csv)

        study = self.study
        supplier = self.supplier

        headers = csv[::SampleManifest::SPREADSHEET_HEADER_ROW]
        headers.each_with_index do |name, index|
          next if name.blank?
          if strip_non_word_characters(name) != strip_non_word_characters(ColumnMap.fields[index])
            @manifest_errors << "Header '#{name}' should be '#{ColumnMap.fields[index]}'"
          end

        end
        column_map= SampleManifest.compute_column_map(headers)

        offset = ::SampleManifest::SPREADSHEET_OFFSET
        offset.upto(csv.size-1) do |n|
          begin
            sanger_sample_id = SampleManifest.read_column_by_name(csv, n, 'SANGER SAMPLE ID', column_map)
            next if sanger_sample_id.blank?
            sample      = Sample.find_by_sanger_sample_id(sanger_sample_id)

            if !sample
              @manifest_errors << "Unable to find sample with Sanger Sample ID #{sanger_sample_id} "
            else
              if sample.updated_by_manifest && ! override_sample_information
                next
              end

              if sample.sample_supplier_name_empty?(SampleManifest.read_column_by_name(csv, n, 'SUPPLIER SAMPLE NAME', column_map))
                sample.empty_supplier_sample_name = true
                sample.save
                next
              end

              check_for_required_fields!(csv[n])

              metadata = {
                  :cohort                      => SampleManifest.read_column_by_name(csv, n, 'COHORT', column_map),
                  :gender                      => SampleManifest.read_column_by_name(csv, n, 'GENDER', column_map),
                  :father                      => SampleManifest.read_column_by_name(csv, n, 'FATHER (optional)', column_map),
                  :mother                      => SampleManifest.read_column_by_name(csv, n, 'MOTHER (optional)', column_map),
                  :sibling                     => SampleManifest.read_column_by_name(csv, n, 'SIBLING (optional)', column_map),
                  :is_resubmitted              => convert_yes_no_to_boolean(SampleManifest.read_column_by_name(csv, n, 'IS RE-SUBMITTED SAMPLE?', column_map)),
                  :country_of_origin           => SampleManifest.read_column_by_name(csv, n, 'COUNTRY OF ORIGIN', column_map),
                  :geographical_region         => SampleManifest.read_column_by_name(csv, n, 'GEOGRAPHICAL REGION', column_map),
                  :ethnicity                   => SampleManifest.read_column_by_name(csv, n, 'ETHNICITY', column_map),
                  :dna_source                  => SampleManifest.read_column_by_name(csv, n, 'DNA SOURCE', column_map),
                  :date_of_sample_collection   => SampleManifest.read_column_by_name(csv, n, 'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)', column_map),
                  :date_of_sample_extraction   => SampleManifest.read_column_by_name(csv, n, 'DATE OF DNA EXTRACTION (MM/YY or YYYY only)', column_map),
                  :sample_extraction_method    => SampleManifest.read_column_by_name(csv, n, 'DNA EXTRACTION METHOD', column_map),
                  :sample_purified             => SampleManifest.read_column_by_name(csv, n, 'SAMPLE PURIFIED?', column_map),
                  :purification_method         => SampleManifest.read_column_by_name(csv, n, 'PURIFICATION METHOD', column_map),
                  :concentration               => SampleManifest.read_column_by_name(csv, n, "CONC. (ng/ul)", column_map),
                  :concentration_determined_by => SampleManifest.read_column_by_name(csv, n, 'CONCENTRATION DETERMINED BY', column_map),
                  :sample_taxon_id             => SampleManifest.read_column_by_name(csv, n, 'TAXON ID', column_map),
                  :sample_description          => SampleManifest.read_column_by_name(csv, n, 'SAMPLE DESCRIPTION', column_map),
                  :sample_ebi_accession_number => SampleManifest.read_column_by_name(csv, n, 'SAMPLE ACCESSION NUMBER (optional)', column_map),
                  :sample_sra_hold             => SampleManifest.read_column_by_name(csv, n, 'SAMPLE VISIBILITY', column_map),
                  :sample_type                 => SampleManifest.read_column_by_name(csv, n, 'SAMPLE TYPE', column_map),
                  :volume                      => SampleManifest.read_column_by_name(csv, n, "VOLUME (ul)", column_map),
                  :sample_storage_conditions   => SampleManifest.read_column_by_name(csv, n, 'DNA STORAGE CONDITIONS', column_map),
                  :supplier_name               => SampleManifest.read_column_by_name(csv, n, 'SUPPLIER SAMPLE NAME', column_map),
                  :gc_content                  => SampleManifest.read_column_by_name(csv, n, 'GC CONTENT', column_map),
                  :sample_public_name          => SampleManifest.read_column_by_name(csv, n, 'PUBLIC NAME',column_map),
                  :sample_common_name          => SampleManifest.read_column_by_name(csv, n, 'COMMON NAME',column_map),
                  :sample_strain_att           => SampleManifest.read_column_by_name(csv, n, 'STRAIN',column_map)
                }

              sample.update_attributes_from_manifest!(
                :empty_supplier_sample_name => false,
                :control                    => convert_yes_no_to_boolean(SampleManifest.read_column_by_name(csv, n, 'IS SAMPLE A CONTROL?', column_map)),
                :updated_by_manifest        => true,
                :sample_metadata_attributes => metadata.delete_if { |_, v| v.nil? }
              )
            end
          rescue ActiveRecord::RecordInvalid => e
            @manifest_errors << e.message
          rescue RequiredFieldMissing => e
            @manifest_errors << e.message
          end
        end
        if !@manifest_errors.empty?
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::Rollback
    rescue FasterCSV::MalformedCSVError => e
      @manifest_errors << "Invalid CSV file, did you upload an EXCEL file by accident? - "+e.message
    rescue NoMethodError => e
      $stderr.puts e.message
      e.backtrace.map(&$stderr.method(:puts))

      @manifest_errors << "Invalid CSV file, did you upload an EXCEL file by accident? - "+e.message
    end

    if !@manifest_errors.empty?
      self.last_errors = @manifest_errors
      self.fail!
    else
      self.last_errors = nil
      self.finished!
    end
    self.save!

  end
end
