# frozen_string_literal: true

##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel
  SequencescapeExcel.initialize

  FIRST_ROW = 11 #9 - changed temporarily to 11, to work with one tube rack - need to make this set dynamically somehow

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
