# frozen_string_literal: true

##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel
  Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)

  FIRST_ROW = 9

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
