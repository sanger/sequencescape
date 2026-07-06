# frozen_string_literal: true

##
# Creates a Bulk Submission Spreadsheet from a bulk submission object
module BulkSubmissionExcel
  SequencescapeExcel.initialize

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
