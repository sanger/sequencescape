module SampleManifestExcel
  class Upload
    class Row
      include ActiveModel::Model

      attr_accessor :number, :data, :columns
      attr_reader :sample, :sanger_sample_id

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns, :sample
      validate :check_primary_receptacle, if: :sample_present?

      delegate :present?, to: :sample, prefix: true

      def initialize(attributes = {})
        super

        @sanger_sample_id ||= if columns.present? && data.present?
                                value(:sanger_sample_id)
                              end

        @sample ||= Sample.find_by(id: sanger_sample_id)

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

    private

      def check_primary_receptacle
        errors.add(:sample, 'Does not have a primary receptacle.') unless sample.primary_receptacle.present?
      end
    end
  end
end
