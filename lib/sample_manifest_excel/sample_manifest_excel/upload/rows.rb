module SampleManifestExcel
  module Upload
    class Rows
      include ActiveModel::Model
      include Enumerable

      attr_reader :items, :data, :columns

      validates_presence_of :data, :columns
      validate :check_rows

      delegate :empty?, :last, to: :items

      def initialize(data, columns)
        @data = data || []
        @columns = columns

        @items = create_rows
      end

      def each(&block)
        items.each(&block)
      end

    private

      def create_rows
        [].tap do |rows|
          data.each_with_index do |r, i|
            rows << Row.new(number: i + 1, data: r, columns: columns)
          end
        end
      end

      def check_rows
        items.each do |row|
          unless row.valid?
            errors.add(:base, row.errors.full_messages)
          end
        end
      end
    end
  end
end
