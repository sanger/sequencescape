# frozen_string_literal: true

module SequencescapeExcel
  module Helpers
    ##
    # Just a little help to create a workbook, package and save that package.
    module Download
      def save(filename)
        xls.serialize(filename)
      end

      def xls
        @xls ||= Axlsx::Package.new
      end

      def workbook
        @workbook ||= xls.workbook
      end
    end
  end
end
