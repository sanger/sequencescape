
# frozen_string_literal: true

module Aker
  # Provides access to the information for an Aker Biomaterial that is spread into different Sequencescape tables.
  # This class allows to read and update the data to keep in sync Aker and Sequencescape copy of the sample
  class Material < Aker::Mapping
    delegate :container, to: :sample
    delegate :volume, :concentration, :amount, to: :container

    alias sample instance

    # Defines the attributes that will be sent back to Aker
    def attributes
      attrs = super
      attrs[:_id] = sample.uuid
      attrs
    end

    # Defines the table related with a model in the config provided
    def model_for_table(table_name, _attr_name = nil)
      return sample if table_name == :sample
      return sample.sample_metadata if table_name == :sample_metadata
      return sample.container.asset.well_attribute if table_name == :well_attribute && sample && sample.container && sample.container.a_well?
      return sample.container.asset if table_name == :well_attribute && sample && sample.container && !sample.container.a_well?
      nil
    end

    def aker_attr_name(table_name, field_name)
      return field_name unless sample
      table_name = :sample if container && !container.a_well? && (table_name == :well_attribute)
      super(table_name, field_name)
    end
  end
end
