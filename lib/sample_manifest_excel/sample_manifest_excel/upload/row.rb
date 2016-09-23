module SampleManifestExcel
  class Upload
    class Row

      include ActiveModel::Validations

      attr_reader :number, :data, :columns

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns, :sample
      validate :check_primary_receptacle, if: Proc.new { |u| u.sample.present? }

      def initialize(number, data, columns)
        @number = number
        @data = data
        @columns = columns
      end

      def sample
        @sample ||= Sample.find_by_id(sanger_sample_id)
      end

      def sanger_sample_id
        @sanger_sample_id ||= if columns.present? && data.present?
          data[self.columns.find_by(:name, :sanger_sample_id).number-1]
        end
      end

    private

      def check_primary_receptacle
        errors.add(:sample, "Does not have a primary receptacle.") unless sample.primary_receptacle.present?
      end

    end
  end
end