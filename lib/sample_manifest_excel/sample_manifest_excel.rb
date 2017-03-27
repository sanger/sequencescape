##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel
  
  require_relative 'sample_manifest_excel/helpers'
  require_relative 'sample_manifest_excel/core_extensions'
  require_relative 'sample_manifest_excel/subclass_checker'
  require_relative 'sample_manifest_excel/cell'
  require_relative 'sample_manifest_excel/list'
  require_relative 'sample_manifest_excel/conditional_formatting_default'
  require_relative 'sample_manifest_excel/conditional_formatting_default_list'
  require_relative 'sample_manifest_excel/manifest_type_list'
  require_relative 'sample_manifest_excel/specialised_field'
  require_relative 'sample_manifest_excel/validation'
  require_relative 'sample_manifest_excel/column'
  require_relative 'sample_manifest_excel/column_list'
  require_relative 'sample_manifest_excel/conditional_formatting'
  require_relative 'sample_manifest_excel/conditional_formatting_list'
  require_relative 'sample_manifest_excel/formula'
  require_relative 'sample_manifest_excel/range'
  require_relative 'sample_manifest_excel/range_list'
  require_relative 'sample_manifest_excel/worksheet'
  require_relative 'sample_manifest_excel/download'
  require_relative 'sample_manifest_excel/tags'
  require_relative 'sample_manifest_excel/test_download'
  require_relative 'sample_manifest_excel/upload'

  Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)

  mattr_accessor :first_row
  self.first_row = 9

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset!
    @configuration = Configuration.new
  end
end
