module SampleManifestExcel
  module Upload
    class Columns

      include ActiveModel::Validations
      include Enumerable

      validate :headings_exist

      def initialize(headings, column_list)
        create_columns(headings, column_list)
      end

      def columns
        @columns ||= {}
      end

      def each(&block)
        columns.each(&block)
      end

    private

      def create_columns(headings, column_list)
        headings.each_with_index do |heading, i|
          columns[i+1] = column_list.find_by_heading(heading) || heading
        end
      end

      def headings_exist
        bad_headings = columns.values.select { |column| column.is_a?(String) }
        errors.add(:headings, "#{bad_headings.join(",")} are not valid.") unless bad_headings.empty?
      end
    end
  end
end