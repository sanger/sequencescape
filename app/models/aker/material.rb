
# frozen_string_literal: true

module Aker
  class Material < Aker::Mapping
    delegate :container, to: :sample

    def sample
      @instance
    end

    def attributes
      attrs = super
      attrs[:_id] = sample.name
      attrs
    end

    def model_for_table(table_name)
      return sample if table_name == :samples
      return sample.sample_metadata if table_name == :sample_metadata
      if table_name == :well_attribute
        if sample.container.is_a_well?
          return sample.container.asset.well_attribute
        else
          return sample.container.asset
        end
      end
      nil
    end

    def aker_attr_name(table_name, field_name)
      return super(table_name, field_name) unless container && !container.is_a_well?
      field_name
    end
  end
end
