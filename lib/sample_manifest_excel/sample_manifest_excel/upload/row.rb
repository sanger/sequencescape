module SampleManifestExcel
  class Upload
    class Row

      include ActiveModel::Validations

      attr_reader :number, :data, :columns, :sanger_sample_id

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns
      validate :check_sanger_sample_id

      def initialize(number, data, columns)
        @number = number
        @data = data
        @columns = columns
        add_sanger_sample_id
      end

    private

      def add_sanger_sample_id
        if columns.present? && data.present?
          @sanger_sample_id = data[self.columns.find_by(:name, :sanger_sample_id).number-1]
        end
      end

      def check_sanger_sample_id
        unless Sample.find_by_id(sanger_sample_id.to_i)
          errors.add(:sample, "is not valid.")
        end
      end
    end
  end
end