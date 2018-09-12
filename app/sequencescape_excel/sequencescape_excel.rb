# frozen_string_literal: true

##
# Used to translate a series of configurations into excel spreadsheets
# via xlsx
module SequencescapeExcel
  def self.initialize
    Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)
  end
end
