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
  include Uuid::Uuidable
  include ModelExtensions::SampleManifest
  include SampleManifest::BarcodePrinterBehaviour
  include SampleManifest::TemplateBehaviour
  include SampleManifest::SampleTubeBehaviour
  include SampleManifest::CoreBehaviour
  include SampleManifest::PlateBehaviour
  include SampleManifest::InputBehaviour
  extend SampleManifest::StateMachine

  module Associations
    def self.included(base)
      base.has_many(:sample_manifests)
    end
  end

  has_many :uploaded,  :class_name => "DbFile", :as => :owner, :conditions => {:owner_type_extended => 'uploaded'}
  has_many :generated, :class_name => "DbFile", :as => :owner, :conditions => {:owner_type_extended => 'generated'}
   
   # #  Mount Carrierwave on report field
   #   mount_uploader :uploaded, PolymorphicUploader, :mount_on => "uploaded_filename"
   #   mount_uploader :generated, PolymorphicUploader, :mount_on => "generated_filename"
  
  class_inheritable_accessor :spreadsheet_offset
  class_inheritable_accessor :spreadsheet_header_row
  self.spreadsheet_offset = 9
  self.spreadsheet_header_row = 8
  
  acts_as_audited :on => [:destroy, :update]
  
  attr_accessor :override
  attr_reader :manifest_errors

  # Needed for the UI to work!
  def barcode_printer ; end
  def template ; end

  belongs_to :supplier
  belongs_to :study
  belongs_to :project
  belongs_to :user
  serialize :last_errors
  serialize :barcodes

  validates_presence_of :supplier
  validates_presence_of :study
  validates_numericality_of :count, :only_integer => true, :greater_than => 0, :allow_blank => false
  
  before_save :default_asset_type
  
  def default_asset_type
    self.asset_type = "plate" if self.asset_type.blank?
  end

  def name
    "Manifest_#{self.id}"
  end

  named_scope :pending_manifests,   { :order => 'id DESC',         :conditions => 'uploaded_file IS NULL'     }
  named_scope :completed_manifests, { :order => 'updated_at DESC', :conditions => 'uploaded_file IS NOT NULL' }
  
  def generate
    @manifest_errors = []

    ActiveRecord::Base.transaction do
      self.barcodes = []
      core_behaviour.generate
    end
    return nil
  end

  def print_labels(barcode_printer)
    core_behaviour.print_labels do |printables, prefix, *args|
      unless printables.empty?
        printables.each { |printable| printable.study = self.study.abbreviation }
        barcode_printer.print_labels(printables, prefix, *args)
      end
    end
    true
  rescue SOAP::FaultError => exception
    false
  end

  def create_sample(sanger_sample_id)
    Sample.create!(:name => sanger_sample_id, :sanger_sample_id => sanger_sample_id, :sample_manifest => self).tap do |sample|
      sample.events.created_using_sample_manifest!(self.user)
    end
  end

  def generate_sanger_ids(count = 1)
    (1..count).map { |_| SangerSampleId::Factory.instance.next! }
  end
  private :generate_sanger_ids

  def generate_study_samples(study_samples_data)
    study_sample_fields = [:study_id, :sample_id]
    StudySample.import study_sample_fields, study_samples_data
  end
end
