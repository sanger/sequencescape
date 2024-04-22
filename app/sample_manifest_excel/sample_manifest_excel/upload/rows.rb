# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    ##
    # A collection of Rows which relates to the data section of an uploaded spreadsheet
    # Rows are valid if all of the rows are valid
    # Expects an Upload::Data object.
    class Rows
      include ActiveModel::Model
      include Enumerable

      attr_reader :items, :data, :columns, :plate_metadata

      validates_presence_of :data, :columns
      validate :check_rows

      delegate :empty?, :last, to: :items

      def initialize(data, columns, cache = SampleManifestAsset)
        @data = data || []
        @columns = columns
        @items = create_rows(cache)
      end

      def each(&)
        items.each(&)
      end

      # Return values for rows for a particular column number
      # there is a similar method data#column(n), but it returns column of data for all rows (including empty ones)
      def data_at(row_num)
        map { |row| row.at(row_num) }
      end

      private

      def create_rows(cache)
        [].tap do |rows|
          data.each_with_index do |r, i|
            row = Row.new(number: i + data.start_row + 1, data: r, columns:, cache:)
            rows << row unless row.empty?
          end
        end
      end

      def check_rows
        items.each { |row| errors.add(:base, row.errors.full_messages) unless row.valid? }
      end
    end
  end
end
