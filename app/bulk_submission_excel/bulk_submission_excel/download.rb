# frozen_string_literal: true

module BulkSubmissionExcel
  ##
  # Download
  class Download
    include ActiveModel::Model
    include SampleManifestExcel::Helpers::Download

    validates_presence_of :column_list, :range_list

    attr_accessor :submission_template, :range_list, :column_list, :assets, :user_login

    def initialize(*args)
      super
      ranges_worksheet
      data_worksheet
    end

    def ranges_worksheet
      @ranges_worksheet ||= SampleManifestExcel::Worksheet::RangesWorksheet.new(ranges: range_list, workbook: workbook) if valid?
    end

    def data_worksheet
      return nil unless valid?
      @data_worksheet ||= BulkSubmissionExcel::Worksheet::DataWorksheet.new(
        workbook: workbook,
        columns: column_list,
        assets: assets,
        ranges: range_list,
        defaults: {
          user_login: user_login,
          template_name: submission_template.name
        }
      )
    end

    def inspect
      "<#{self.class}: @submission_template=#{@submission_template}, @assets=#{@assets} ...>"
    end
  end
end
