module SampleManifestExcel
  class Upload
    class Row

      include ActiveModel::Validations

      attr_reader :number, :data, :columns

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns, :sample

      validate :check_primary_receptacle
      validate :check_sample_container, if: :primary_receptacle_present?

      def initialize(number, data, columns)
        @number = number
        @data = data
        @columns = columns
      end

      def at(n)
        data[n-1]
      end

      def value(key)
        at(columns.find_by_or_null(:name, key).number)
      end

      def sample
        @sample ||= Sample.find_by_id(sanger_sample_id)
      end

      def sanger_sample_id
        @sanger_sample_id ||= if columns.present? && data.present?
          value(:sanger_sample_id)
        end
      end

      def sample_present?
        sample.present?
      end

      def primary_receptacle_present?
        return false unless sample_present?
        sample.primary_receptacle.present?
      end

      def first?
        number == 1
      end

    private



      def check_primary_receptacle
        errors.add(:sample, "Does not have a primary receptacle.") unless primary_receptacle_present?
      end

      def check_sample_container
        type_column = columns.find_by(:name, :sanger_plate_id) || columns.find_by(:name, :sanger_tube_id)
        return if type_column.nil?
        if type_column.name == :sanger_plate_id
          unless data[type_column.number-1] == sample.wells.first.plate.sanger_human_barcode && data[columns.find_by(:name, :well).number-1] == sample.wells.first.map.description
            errors.add(:sample, "You can not move samples between wells or modify barcodes")
          end
        else
          unless data[type_column.number-1] == sample.assets.first.sanger_human_barcode
            errors.add(:sample, "You can not move samples between tubes or modify barcodes")
          end
        end
      end

    end
  end
end