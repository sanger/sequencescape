# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlateResource < BaseResource
      # Constants...

      # immutable # comment to make the resource mutable

      default_includes :uuid_object, :barcodes, :plate_purpose, :transfer_requests

      # Associations:
      has_one :purpose, readonly: true, foreign_key: :plate_purpose_id
      has_one :custom_metadatum_collection

      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true
      has_many :wells, readonly: true
      has_many :comments, readonly: true

      has_many :ancestors, readonly: true, polymorphic: true
      has_many :descendants, readonly: true, polymorphic: true
      has_many :parents, readonly: true, polymorphic: true
      has_many :children, readonly: true, polymorphic: true

      has_many :child_plates, readonly: true
      has_many :child_tubes, readonly: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :labware_barcode, readonly: true
      # attribute :pools, readonly: true
      attribute :state, readonly: true
      attribute :number_of_rows, readonly: true, delegate: :height
      attribute :number_of_columns, readonly: true, delegate: :width

      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :purpose_name, apply: (lambda do |records, value, _options|
        purpose = Purpose.find_by(name: value)
        records.where(plate_purpose_id: purpose)
      end)
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'machine_barcode' => _model.machine_barcode,
          'human_barcode' => _model.human_barcode
        }
      end

      # This wraps the default PlateResource behaviour, so if the plate purpose has been
      # stored in context by PlateProcessor it will create the instance of Plate model
      # using the purpose creation method.
      def self.create(context)
        purpose_uuid = context[:plate_purpose_uuid]
        return new(PlatePurpose.with_uuid(purpose_uuid).first.create!, context) if purpose_uuid

        super
      end

      # Custom methods for Plate creation
      HERON_PLATE_CREATION_ATTRS = %i[barcode wells_content plate_purpose_uuid study_uuid].freeze

      attributes(*HERON_PLATE_CREATION_ATTRS)

      def self.fetchable_fields(context)
        super - HERON_PLATE_CREATION_ATTRS
      end

      attr_accessor :plate_purpose_uuid, :study_uuid

      def barcode
        @model.barcodes.map(&:barcode)
      end

      def barcode=(barcode)
        barcode_format = Barcode.matching_barcode_format(barcode)
        @model.errors.add(:base, "The barcode '#{barcode}' is not a recognised format.") && return if barcode_format.nil?
        @model.barcodes << Barcode.new(asset: @model, barcode: barcode, format: barcode_format) if @model.barcodes.where(barcode: barcode).count.zero?
      end

      def wells_content
        nil
      end

      def wells_content=(wells_content)
        factory = ::Heron::Factories::WellsContent.new(wells_content)
        if factory.valid?
          factory.add_aliquots_into_plate(@model)
        else
          @model.errors.add(:wells_content, factory.errors)
          raise @model.errors.full_messages.join('')
        end
      end

      # Class method overrides
    end
  end
end
