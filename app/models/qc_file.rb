class QcFile < ActiveRecord::Base
  extend DbFile::Uploader
  include Uuid::Uuidable

  module Associations
    # Adds accessors for named fields and attaches documents to them

    def has_qc_files
      line = __LINE__ + 1
      class_eval(%Q{
        has_many(:qc_files, {:as => :asset, :dependent => :destroy })

        def add_qc_file(file, filename=nil, filetype=nil)
          puts "Add qc file"
          opts = {:uploaded_data => {:tempfile=>file, :filename=>filename, :filetype=>filetype}}
          opts.merge!(:filename=>filename) unless filename.nil?
          QcFile.set_validator(opts)
          qc_files.create!(opts) unless file.blank?
        end

      }, __FILE__, line)
    end

  end

  belongs_to :asset, :polymorphic => true

  # CarrierWave uploader - gets the uploaded_data file, but saves the identifier to the "filename" column
  has_uploaded :uploaded_data, {:serialization_column => "filename"}

  # Method provided for backwards compatibility
  def current_data
    uploaded_data.read
  end

  def retrieve_file
    begin
      uploaded_data.cache!(uploaded_data.file)
      yield(uploaded_data)
    ensure
      # Clear the cached file once done
      uploaded_data.file.delete
    end
  end

  # Handle some of the metadata with this callback
  before_create :validates_file
  before_save :update_document_attributes
  after_save :store_file_extracted_data

  def self.set_validator(opts)
    if (opts[:uploaded_data][:filetype] == "bioanalyzer")
        @file_extractor = Parsers::BioanalysisCsvParser.new(opts[:uploaded_data][:filename], opts[:uploaded_data][:tempfile])
    end
  end

  def self.get_validator
    @file_extractor
  end

  def validates_file
    @file_extractor = self.class.get_validator
    return true if @file_extractor.nil?
    @file_extractor.validates_content?
  end

  def store_file_extracted_data
    extractor = self.class.get_validator
    self.asset.wells.each do |well|
      # Is everything updated always or just the well specified in the report??
      position = well.map.description
      # It's updating directly the assets table, not the well_attributes
      #well.concentration = extractor.concentration(position)
      well.set_concentration(extractor.concentration(position))
      well.set_molarity(extractor.molarity(position))
      well.save
    end
    true
  end

  private

    # Save Size/content_type Metadata
    def update_document_attributes
      if uploaded_data.present?
        self.content_type = uploaded_data.file.content_type
        self.size    = uploaded_data.file.size
      end
    end
end

