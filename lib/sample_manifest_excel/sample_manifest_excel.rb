##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel

  Hash.send(:include, CoreExtensions::Hash)
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

  module Helpers
    def load_file(folder, filename)
      YAML::load_file(File.join(Rails.root, folder,"#{filename}.yml")).with_indifferent_access
    end
  end
end