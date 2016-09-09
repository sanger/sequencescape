module SampleManifestExcel
  module Upload
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
    end
  end
end