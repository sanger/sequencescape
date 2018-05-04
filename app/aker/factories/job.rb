# frozen_string_literal: true

module Aker
  module Factories
    ##
    # A job consists of an aker_job_id and materials (samples).
    # Validates presence of aker_job_id and ensures that there is at least one material.
    class Job
      include ActiveModel::Model
      ATTRIBUTES = %i[job_id work_order_id product_name process_name process_uuid modules product_version product_uuid project_uuid project_name cost_code container materials comment desired_date data_release_uuid].freeze
      DEFAULT_ATTRIBUTES = { materials: {} }.freeze

      attr_accessor(*ATTRIBUTES)
      attr_reader :aker_job_id, :model

      validates_presence_of :aker_job_id, :data_release_uuid, :materials

      validate :check_materials, :check_study

      def self.create(params)
        new(params).create
      end

      def initialize(params = {})
        @container_params = params.to_h.with_indifferent_access[:container]
        super(DEFAULT_ATTRIBUTES.merge(params))
        @aker_job_id = job_id
      end

      def materials=(materials)
        @materials = build_materials(materials)
      end

      ##
      # Persists a Job and all associated materials.
      def create
        return unless valid?
        @model = Aker::Job.create(aker_job_id: aker_job_id, samples: collect_materials)
      end

      def as_json(_options = {})
        {
          job: json_attributes
        }
      end

      private

      def json_attributes
        {}.tap do |json|
          ATTRIBUTES.each do |attribute|
            json[attribute] = json_attribute(attribute)
          end
        end
      end

      def json_attribute(attribute)
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

      def build_materials(materials)
        (materials || []).collect do |material|
          indifferent_material = material.to_h.with_indifferent_access
          Sample.find_by(name: indifferent_material[:_id]) ||
            Aker::Factories::Material.new(indifferent_material).tap do |m|
              m.container = build_container(m, indifferent_material[:address])
            end
        end
      end

      def build_container(_material, address)
        Aker::Factories::Container.new(@container_params.merge(address: address))
      end

      def check_materials
        materials.each do |material|
          next if material.valid?
          material.errors.each do |key, value|
            errors.add key, value
          end
        end
      end

      def check_study
        study = Uuid.find_by(external_id: data_release_uuid)
        if study.nil?
          errors.add(:data_release_uuid, 'is unknown')
        else
          errors.add(:data_release_uuid, 'is not active') unless Study.find(study.resource_id).active?
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
