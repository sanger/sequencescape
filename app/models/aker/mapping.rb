# frozen_string_literal: true

module Aker
  #
  # This class synchronizes the data between Aker biomaterial fields and SS by mapping tables and columns in SS with
  # property names from Aker materials service
  #
  # To be able to update between Aker and SS we need to map the Aker field names with the corresponding SS
  # tables and columns.
  #
  # IMPORTANT!!
  # Read the docs in config/initializers/aker.rb before editing this file
  class Mapping
    attr_accessor :instance

    class << self
      attr_accessor :config
    end

    def initialize(instance)
      raise 'Please update config/initializers/aker.rb with a config that describes the mapping.' if config.nil?
      @instance = instance
    end

    def update(attrs)
      _each_model_and_setting_attrs_for(attrs) do |model, setting_attrs|
        model.update(setting_attrs)
      end
    end

    def update!(attrs)
      _each_model_and_setting_attrs_for(attrs) do |model, setting_attrs|
        model.update!(setting_attrs)
      end
    end

    def attributes
      {}.tap do |obj|
        config[:updatable_attrs_from_ss_into_aker].each do |k|
          table_name = table_for_attr(k)
          model = model_for_table(table_name)
          if model
            attr_name = aker_attr_name(table_name, k)
            value = model.send(attr_name)
          end
          obj[k] = value if value
        end
      end
    end

    private

    def config
      self.class.config
    end

    def _each_model_and_setting_attrs_for(attrs)
      attrs.keys.all? do |attr_name|
        table_name = table_for_attr(attr_name)

        # Ignore attributes that dont belong to any model
        next true unless table_name

        setting_attrs = attributes_for_table(table_name, attrs)
        model = model_for_table(table_name)
        yield model, setting_attrs
      end
    end

    def model_for_table(_table_name)
      raise 'Not implemented'
    end

    def table_for_attr(attr_name)
      config[:map_ss_tables_with_aker].keys.each do |table_name|
        return table_name if config[:map_ss_tables_with_aker][table_name].include?(attr_name.to_sym)
      end
      nil
    end

    def attributes_for_table(table_name, attrs)
      valid_keys = config[:map_ss_tables_with_aker][table_name] & config[:updatable_attrs_from_aker_into_ss]
      valid_attrs(table_name, valid_keys, attrs)
    end

    def aker_attr_name(table_name, field_name)
      return field_name unless config[:map_aker_with_ss_columns][table_name]
      config[:map_aker_with_ss_columns][table_name][field_name] || field_name
    end

    def valid_attrs(table_name, valid_keys, attrs)
      obj = attrs.select { |k, _v| valid_keys.include?(k.to_sym) }
      memo = {}
      obj.each_pair do |k, v|
        memo[aker_attr_name(table_name, k.to_sym)] = v
      end
      memo
    end
  end
end
