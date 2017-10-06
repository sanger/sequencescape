module Aker
  module Factories
    ##
    # A workOrder consists of an aker_id and materials (samples).
    # Validates presence of aker_id and ensures that there is at least one material.
    class WorkOrder
      include ActiveModel::Model

      ATTRIBUTES = [ :work_order_id, :product_name, :product_version, :product_uuid, :proposal_id, :proposal_name, :cost_code, :materials, :comment, :desired_date ]
      DEFAULT_ATTRIBUTES = { materials: {} }

      attr_accessor *ATTRIBUTES
      attr_reader :aker_id, :model

      validates_presence_of :aker_id, :materials

      validate :check_materials

      def self.create(params)
        new(params).create
      end

      def initialize(params = {})
        super(DEFAULT_ATTRIBUTES.merge(params))

        @aker_id = work_order_id
      end

      def materials=(materials)
        @materials = create_materials(materials)
      end

      ##
      # Persists a Work Order and all associated materials.
      def create
        return unless valid?
        @model = Aker::WorkOrder.create(aker_id: aker_id, samples: collect_materials)
      end

      def as_json(_options = {})
        {
          work_order: get_json_attributes
        }
      end

      private

      def get_json_attributes
         {}.tap do |json|
          ATTRIBUTES.each do |attribute|
            json[attribute] = get_json_attribute(attribute)
          end
        end
      end

      def get_json_attribute(attribute)
        value = send(attribute)
        case value
        when Array
          value.collect(&:as_json)
        when /^(\d)+$/
          value.to_i
        else
          value
        end
      end

      def create_materials(materials)
        (materials || []).collect do |material|
          indifferent_material = material.to_h.with_indifferent_access
          Sample.find_by_name(indifferent_material[:_id]) || Aker::Factories::Material.new(indifferent_material)
        end
      end

      def check_materials
        materials.each do |material|
          next if material.valid?
          material.errors.each do |key, value|
            errors.add key, value
          end
        end
      end

      def collect_materials
        materials.collect do |material|
          material.instance_of?(Aker::Factories::Material) ? material.create : material
        end
      end
    end
  end
end
