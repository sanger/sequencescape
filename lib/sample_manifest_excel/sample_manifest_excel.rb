##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel
  require_relative 'sample_manifest_excel/hash_attributes'
  require_relative 'sample_manifest_excel/core_extensions'
  require_relative 'sample_manifest_excel/null_range'
  require_relative 'sample_manifest_excel/null_validation'
  require_relative 'sample_manifest_excel/attributes'
  require_relative 'sample_manifest_excel/cell'
  require_relative 'sample_manifest_excel/conditional_formatting_default'
  require_relative 'sample_manifest_excel/conditional_formatting_default_list'
  require_relative 'sample_manifest_excel/manifest_type_list'
  require_relative 'sample_manifest_excel/column'
  require_relative 'sample_manifest_excel/column_list'
  require_relative 'sample_manifest_excel/conditional_formatting'
  require_relative 'sample_manifest_excel/conditional_formatting_list'
  require_relative 'sample_manifest_excel/formula'
  require_relative 'sample_manifest_excel/range'
  require_relative 'sample_manifest_excel/range_list'
  require_relative 'sample_manifest_excel/worksheet'
  require_relative 'sample_manifest_excel/download'

  module Helpers
    def load_file(folder, filename)
      YAML::load_file(File.join(Rails.root, folder, "#{filename}.yml")).with_indifferent_access
    end
  end

  Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)

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
