# frozen_string_literal: true

module BulkSubmissionExcel
  ##
  # Download
  class Download
    include ActiveModel::Model
    include SequencescapeExcel::Helpers::Download

    validates_presence_of :column_list, :range_list

    attr_accessor :submission_template, :range_list, :column_list, :assets, :defaults

    def initialize(*args)
      super
      ranges_worksheet
      data_worksheet
    end

    def new_record?
      true
    end

    def ranges_worksheet
      return unless valid?
        @ranges_worksheet ||= SequencescapeExcel::Worksheet::RangesWorksheet.new(ranges: range_list, workbook:)
      
    end

    def submission_template_id=(id)
      self.submission_template = SubmissionTemplate.find_by(id:)
    end

    def submission_template_id
      submission_template&.id
    end

    def data_worksheet
      return nil unless valid?

      @data_worksheet ||=
        BulkSubmissionExcel::Worksheet::DataWorksheet.new(
          workbook:,
          columns: column_list,
          assets:,
          ranges: range_list,
          defaults:
        )
    end

    def inspect
      "<#{self.class}: @submission_template=#{@submission_template}, @assets=#{@assets} ...>"
    end
  end
end
