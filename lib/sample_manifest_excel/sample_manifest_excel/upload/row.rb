module SampleManifestExcel
  module Upload
    ##
    # A Row relates to a row in a sample manifest spreadsheet.
    # Each Row relates to a sample
    # Required fields:
    # *number: Number of the row which is used for error tracking
    # *data: An array of sample data
    # *columns: The columns which relate to the data.
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

      ##
      # Finds a sample based on the sanger_sample_id column. Must exist for row to be valid.
      # Creates the specialised fields for updating the sample based on the passed columns
      def initialize(attributes = {})
        super

        @sanger_sample_id ||= if columns.present? && data.present?
                                value(:sanger_sample_id)
                              end

        @sample ||= Sample.find_by(id: sanger_sample_id)
        @specialised_fields = create_specialised_fields
      end

      ##
      # Finds the data value for a particular column.
      # Offset by 1. Columns have numbers data is an array
      def at(n)
        data[n - 1]
      end

      ##
      # Find a value based on a column name
      def value(key)
        at(columns.find_by_or_null(:name, key).number)
      end

      def first?
        number == 1
      end

      ##
      # Used for errors
      def row_title
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

      ##
      # Updating the sample involves:
      # *Updating all of the specialised fields in the aliquot
      # *Updating the sample metadata
      # *Saving the aliquot, metadata and sample
      def update_sample(tag_group)
        if valid?
          update_specialised_fields(tag_group)
          update_metadata_fields
          aliquot.save
          metadata.save
          @sample_updated = sample.save
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

      ##
      # If it is a multiplexed library tube the aliquot is transferred
      # from the library tube to a multiplexed library tube and stated set to passed.
      def transfer_aliquot
        if valid?
          sample.primary_receptacle.requests.each do |request|
            request.manifest_processed!
            @aliquot_transferred = true
          end
        end
      end

      def sample_updated?
        @sample_updated
      end

      def aliquot_transferred?
        @aliquot_transferred
      end

    private

      def check_primary_receptacle
        errors.add(:base, "#{row_title} Does not have a primary receptacle.") unless sample.primary_receptacle.present?
      end

      def check_specialised_fields
        if errors.empty?
          specialised_fields.each do |specialised_field|
            unless specialised_field.valid?
              errors.add(:base, "#{row_title} #{specialised_field.errors.full_messages.join(', ')}")
            end
          end
        end
      end

      def check_sample_present
        unless sample_present?
          errors.add(:base, "#{row_title} Sample can't be blank.")
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
