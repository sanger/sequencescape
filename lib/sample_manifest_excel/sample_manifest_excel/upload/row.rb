module SampleManifestExcel
  class Upload
    class Row
      include ActiveModel::Validations

      attr_reader :number, :data, :columns

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns

      def initialize(number, data, columns)
        @number = number
        @data = data
        @columns = columns
      end

      def at(n)
        data[n - 1]
      end

      def value(key)
        at(columns.find_by_or_null(:name, key).number)
      end

      def first?
        number == 1
      end
    end
  end
end
