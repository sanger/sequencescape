module SampleManifestExcel
  ##
  # A worksheet takes data and creates an Excel spreadsheet:
  # - Data Worksheet (to be filled in by client)
  # - Ranges Worksheet (hidden worksheet used by data worksheet to store data about ranges
  #   used for conditional formatting)

  module Worksheet
    require_relative 'worksheet/base'
    require_relative 'worksheet/data_worksheet'
    require_relative 'worksheet/ranges_worksheet'
  end
end
