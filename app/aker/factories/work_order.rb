module Aker
  module Factories

    ##
    # A workOrder consists of an aker_id and materials (samples).
    # All other attributes are rejected.
    # Validates presence of aker_id and ensures that there is at least one material.
    class WorkOrder
      include ActiveModel::Model

      attr_reader :aker_id, :materials, :model

      validates_presence_of :aker_id, :materials

      validate :check_materials

      def self.create(params)
        new(params).create
      end

      def initialize(params)
        @aker_id = params[:work_order_id]
        @materials = create_materials(params[:materials])
      end

      ##
      # Persists a Work Order and all associated materials.
      def create
        return unless valid?
        @model = Aker::WorkOrder.create(aker_id: aker_id, samples: materials.collect(&:create))
      end

      def as_json(_options = {})
        model.as_json
      end

      private

      def create_materials(materials)
        (materials || []).collect do |material|
          Aker::Factories::Material.new(material)
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
    end
  end
end
