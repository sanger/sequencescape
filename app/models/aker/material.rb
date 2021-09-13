# frozen_string_literal: true

module Aker
  # Provides access to the information for an Aker Biomaterial that is spread into different Sequencescape tables.
  # This class allows to read and update the data to keep in sync Aker and Sequencescape copy of the sample
  class Material < Aker::Mapping
    attr_accessor :instance

    delegate :container, to: :sample
    delegate :volume, :concentration, :amount, to: :container

    alias sample instance

    def initialize(instance)
      @instance = instance
    end

    class << self
      def config
        Aker::Material.config = Rails.configuration.aker[:material_mapping] if @config.nil?
        @config
      end
    end

    # Defines the attributes that will be sent back to Aker
    def attributes
      attrs = super
      attrs[:_id] = sample.uuid
      attrs
    end

    # Defines the table related with a model in the config provided
    # rubocop:todo Metrics/PerceivedComplexity, Metrics/AbcSize
    def model_for_table(table_name) # rubocop:todo Metrics/CyclomaticComplexity
      return sample if table_name == :sample
      return sample.sample_metadata if table_name == :sample_metadata
      if table_name == :well_attribute && sample && sample.container && sample.container.a_well?
        return sample.container.asset.well_attribute
      end
      if table_name == :well_attribute && sample && sample.container && !sample.container.a_well?
        return sample.container.asset
      end

      nil
    end

    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    def columns_for_table_from_field(table_name, field_name)
      return field_name unless sample

      table_name = :sample if container && !container.a_well? && (table_name == :well_attribute)
      super(table_name, field_name)
    end
  end
end
