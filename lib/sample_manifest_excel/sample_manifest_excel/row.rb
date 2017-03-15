module SampleManifestExcel
  class Upload
    class Row
      include ActiveModel::Model

      attr_accessor :number, :data, :columns
      attr_reader :sample, :sanger_sample_id

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns
      validate :check_sample_present
      validate :check_primary_receptacle, if: :sample_present?
      validate :check_specialised_fields
      delegate :present?, to: :sample, prefix: true

      def initialize(attributes = {})
        super

        @sanger_sample_id ||= if columns.present? && data.present?
                                value(:sanger_sample_id)
                              end

        @sample ||= Sample.find_by(id: sanger_sample_id)
        @specialised_fields = create_specialised_fields
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

      def row_to_s
        "Row #{number} -"
      end

      def aliquot
        @aliquot ||= sample.aliquots.first
      end

      def metadata
        @metadata ||= sample.sample_metadata
      end

      def specialised_fields
        @specialised_fields ||= []
      end

      def update(tag_group)
        if valid?
          update_specialised_fields(tag_group)
          update_metadata_fields
        end
      end

      def update_specialised_fields(tag_group)
        specialised_fields.each do |specialised_field|
          specialised_field.update(aliquot: aliquot, tag_group: tag_group)
        end
      end

      def update_metadata_fields
        columns.with_metadata_fields.each do |column|
          value = at(column.number)
          column.update_metadata(metadata, value) if value.present?
        end
      end

    private

      def check_primary_receptacle
        errors.add(:base, "#{row_to_s} Does not have a primary receptacle.") unless sample.primary_receptacle.present?
      end

      def check_specialised_fields
        if errors.empty?
          specialised_fields.each do |specialised_field|
            unless specialised_field.valid?
              errors.add(:base, "#{row_to_s} #{specialised_field.errors.full_messages.to_s}")
            end
          end
        end
      end

      def check_sample_present
        unless sample_present?
          errors.add(:base, "#{row_to_s} Sample can't be blank.")
        end
      end

      def create_specialised_fields
        if columns.present? && data.present? && sample.present?
          [].tap do |specialised_fields|
            columns.with_specialised_fields.each do |column|
              specialised_fields << column.specialised_field.new(value: at(column.number), sample: sample)
            end
          end
        end
      end
    end
  end
end
