class ColumnMap
  # TODO: Make data driven?

  @@fields = ['SANGER PLATE ID',
       'WELL',
       'SANGER SAMPLE ID',
       'SUPPLIER SAMPLE NAME',
       'COHORT',
       "VOLUME (ul)",
       "CONC. (ng/ul)",
       'GENDER',
       'COUNTRY OF ORIGIN',
       'GEOGRAPHICAL REGION',
       'ETHNICITY',
       'DNA SOURCE',
       'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',
       'DATE OF DNA EXTRACTION (MM/YY or YYYY only)',
       'IS SAMPLE A CONTROL?',
       'IS RE-SUBMITTED SAMPLE?',
       'DNA EXTRACTION METHOD',
       'SAMPLE PURIFIED?',
       'PURIFICATION METHOD',
       'CONCENTRATION DETERMINED BY',
       'DNA STORAGE CONDITIONS',
       'MOTHER (optional)',
       'FATHER (optional)',
       'SIBLING (optional)',
       'GC CONTENT',
       'PUBLIC NAME',
       'TAXON ID',
       'COMMON NAME',
       'SAMPLE DESCRIPTION',
       'STRAIN',
       'SAMPLE VISIBILITY',
       'SAMPLE TYPE',
       'SAMPLE ACCESSION NUMBER (optional)']

    def self.[](x)
      @@fields.index(x)
    end

    def self.fields
      @@fields
    end
    
    def self.required_columns
      ["VOLUME (ul)",
      "CONC. (ng/ul)"]
    end
end


class SampleManifest < ActiveRecord::Base
  class ProcessingError < Exception
  end
  
  class RequiredFieldMissing < Exception
  end

  has_attached_file :uploaded, :storage => :database
  has_attached_file :generated, :storage => :database
  default_scope select_without_file_columns_for(:uploaded)
  default_scope select_without_file_columns_for(:generated)

  class_inheritable_accessor :spreadsheet_offset
  class_inheritable_accessor :spreadsheet_header_row
  self.spreadsheet_offset = 9
  self.spreadsheet_header_row = 8
  
  acts_as_audited :on => [:destroy, :update]

  # Problem with paperclip
  attr_accessor :uploaded_file_name
  attr_accessor :uploaded_content_type
  attr_accessor :uploaded_file_size
  attr_accessor :uploaded_updated_at

  attr_accessor :generated_file_name
  attr_accessor :generated_content_type
  attr_accessor :generated_file_size
  attr_accessor :generated_updated_at
  
  attr_accessor :override
  attr_accessor :template #TODO do something

  belongs_to :supplier
  belongs_to :study
  belongs_to :project
  belongs_to :user
  has_many   :samples

  validates_presence_of :supplier
  validates_presence_of :study
  serialize :last_errors
  serialize :barcodes
  
  before_save :default_asset_type
  
  include SampleManifest::PlateManifest
  include SampleManifest::TubeManifest
  extend SampleManifest::StateMachine

  def default_asset_type
    if self.asset_type.blank?
      self.asset_type = "plate"
    end
  end

  def name
    "Manifest_#{self.id}"
  end

  def barcode_printer
  end

  def manifest_errors
    @manifest_errors
  end

  def self.pending_manifests
    SampleManifest.find(:all, :order => "id desc", :conditions => 'uploaded_file is null')
  end

  def self.completed_manifests
    SampleManifest.find(:all, :order => "updated_at desc", :conditions => 'uploaded_file is not null')
  end

  def generate(template, barcode_printer)
    @manifest_errors = []

    # Move to validation on study?
    if self.study.abbreviation !~ /^[\w_-]+$/i
      @manifest_errors << "Study abbreviation can not contain spaces or be blank"
      return
    end

    ActiveRecord::Base.transaction do
      spreadsheet = Spreadsheet.open(RAILS_ROOT + (template.path || '/data/base_manifest.xls'))
      worksheet1  = spreadsheet.worksheets.first
      study       = Study.find(self.study_id)

      @column_position_map = read_column_position(worksheet1)

      template.set_value(worksheet1, :study, study.abbreviation)
      template.set_value(worksheet1, :supplier, Supplier.find(self.supplier_id).name)
      template.set_value(worksheet1, :number_of_plates, self.count)

      #worksheet1.row(4)[1] = study.abbreviation # Study
      #worksheet1.row(5)[1] = Supplier.find(self.supplier_id).name # Supplier
      #worksheet1.row(6)[1] = self.count # Number of plates

      # Truncate the number of rows in the spreadsheet.  This improves performance dramatically because the 
      # number of rows in the original sheet is 9999, which means 20s of unnecessary data processing.  This
      # change causes times to drop to < 1s. An extra offset is required because Excel does things in blocks of 32 rows
      if asset_type == '1dtube'
        generate_1dtubes(worksheet1, self.count, barcode_printer, template.default_values)
        worksheet1.dimensions[1] = self.spreadsheet_offset + (self.count) + 64
      else
        generate_plates(worksheet1, self.count, barcode_printer, template.default_values)
        worksheet1.dimensions[1] = self.spreadsheet_offset + (self.count*96) + 64
      end
      
      Tempfile.open(File.basename(spreadsheet.io.path)) do |tempfile|
        spreadsheet.write(tempfile.path)  # Write out the spreadsheet
        tempfile.open                     # Reopen the temporary file
        self.update_attributes!(:generated => tempfile)
      end
    end
    return nil
  end

  def self.compute_column_map(names)
    Hash[names.each_with_index.map  { |name, index| [name && name.strip.gsub(/\s+/," "), index]}]
  end

  def read_column_position(worksheet)
    SampleManifest.compute_column_map(worksheet.row(self.spreadsheet_header_row))
  end

  def clean_up_value(value)
    return "" if value.nil?
    value.strip
  end

  def clean_up_sheet(csv)
    # Clean up CSV
    0.upto(csv.size-1) do |row|
      0.upto(csv[row].size) do |col|
        csv[row][col] = clean_up_value(csv[row][col])
      end
    end
    csv
  end

  def strip_non_word_characters(value)
    return "" if value.nil?
    value.gsub(/[^:alnum:]+/, '')
  end

 
  def check_for_required_fields!(row)
    ColumnMap.required_columns.each do  |column_name|
      raise RequiredFieldMissing, "#{column_name} is required for #{row[ColumnMap['SANGER SAMPLE ID']]}" if row[ColumnMap[column_name]].blank?
    end
  end

  # Always allow 'empty' samples to be updated, but non-empty samples need to have the override checkbox set for an update to occur
  def process(override_sample_information = false, current_user = nil)
    self.start!
    @manifest_errors = []

    begin
      ActiveRecord::Base.transaction do

        csv  = FasterCSV.parse(uploaded.data)
        clean_up_sheet(csv)

        study = self.study
        supplier = self.supplier

        headers = csv[self.spreadsheet_header_row]
        headers.each_with_index do |name, index|
          next if name.blank?
          if strip_non_word_characters(name) != strip_non_word_characters(ColumnMap.fields[index])
            @manifest_errors << "Header '#{name}' should be '#{ColumnMap.fields[index]}'"
          end

        end
        column_map= SampleManifest.compute_column_map(headers)

        samples = []
        offset = self.spreadsheet_offset
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

              sample.update_attributes_from_manifest!({
                :empty_supplier_sample_name => false,
                :control                    => convert_yes_no_to_boolean(SampleManifest.read_column_by_name(csv, n, 'IS SAMPLE A CONTROL?', column_map)),
                :updated_by_manifest        => true,
                :sample_metadata_attributes => metadata.inject({}) { |h, (k, v)| v.nil? ? h : h.update(k=>v)}},
                current_user
              )
              samples << sample
            end
          rescue ActiveRecord::RecordInvalid => e
            @manifest_errors << e.message
          rescue RequiredFieldMissing => e
            @manifest_errors << e.message
          end
        end
        
        plates_update_events(samples, current_user)
        
        if !@manifest_errors.empty?
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::Rollback
    rescue FasterCSV::MalformedCSVError => e
      @manifest_errors << "Invalid CSV file, did you upload an EXCEL file by accident? - "+e.message
    rescue NoMethodError => e
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
  handle_asynchronously :process

  def self.create_sample(study_abbreviation, manifest = nil,sanger_sample_id = nil)
    sanger_sample_id ||= SangerSampleId.generate_sanger_sample_id!(study_abbreviation)
    sample = Sample.create!(:name => sanger_sample_id, :sanger_sample_id => sanger_sample_id, :sample_manifest => manifest)
    sample.events.created_using_sample_manifest!(manifest.user)
    sample
  end

  def generate_sanger_ids(count = 1)
    (1..count).map { |_| SangerSampleId.create!.sample_id }
  end

  def delayed_generate_study_samples(study_samples_data)
    study_sample_fields = [:study_id, :sample_id]
    StudySample.import study_sample_fields, study_samples_data
  end
  handle_asynchronously :delayed_generate_study_samples

  def fill_row_with_default_values(worksheet, current_row, default_values)
    return unless default_values
    default_values.each do |key, value|
      position = @column_position_map[key]
      next unless position
      worksheet[current_row, position] = value
    end
  end

  def delayed_generate_asset_requests_with_ids(asset_ids,study_id)
    RequestFactory.create_assets_requests(asset_ids, study_id)
  end
  handle_asynchronously :delayed_generate_asset_requests_with_ids

  def delayed_generate_asset_requests(assets,study)
    delayed_generate_asset_requests_with_ids(assets.map(&:id), study.id)
  end
  
  def convert_yes_no_to_boolean(value)
    if value and  value.match(/Y/i)
      return true
    end
    
    false
  end

  def self.read_column_by_name(csv, row, name, column_map, default_value=nil)
    col = column_map[name]
    return default_value unless col
    return csv[row][col]
  end

  def self.find_sample_manifest_from_uploaded_spreadsheet(spreadsheet_file)
    begin
      csv  = FasterCSV.parse(spreadsheet_file.read)
      column_map = compute_column_map(csv[self.spreadsheet_header_row])

      offset = self.spreadsheet_offset
      offset.upto(csv.size-1) do |n|
        sanger_sample_id = SampleManifest.read_column_by_name(csv, n, 'SANGER SAMPLE ID', column_map)
        next if sanger_sample_id.blank?
        sample = Sample.find_by_sanger_sample_id(sanger_sample_id)
        next if sample.nil?
        return sample.sample_manifest
      end
    rescue
      nil
    end
    nil
  end

end
