# frozen_string_literal: true

module Aker
  #
  # This class synchronizes the data between Aker biomaterial fields and SS by mapping tables and columns in SS with
  # property names from Aker materials service
  #
  # To be able to update between Aker and SS we need to map the Aker field names with the corresponding SS
  # tables and columns.
  #
  # The config setting defines the mapping between models and attributes in Sequencescape and
  # attributes from the biomaterials service in Aker, as defined by the Job creation.

  # To add a new mapping field from Aker:
  #
  # 1. Add the field name from aker as a value inside the corresponding list for the key with the SS table name
  #     in MAP_SS_TABLES_WITH_AKER
  # 2. Add the field name from aker as a key linked with a column name for SS in MAP_AKER_WITH_SS_COLUMNS
  #
  # After this, if we want to update a new property from Aker into SS models we have to add the field name
  # from aker inside the list UPDATABLE_ATTRS_FROM_AKER_INTO_SS.
  #
  # If we want to update a change in SS into the properties of Aker in the biomaterial service we have to add
  # the field name from aker inside the list UPDATABLE_ATTRS_FROM_SS_INTO_AKER.
  #
  # SS updates will occur on update_attributes() calls
  # Aker updates will happen on job completion, because the job message for the material is generated from
  # the attributes() method of this class.
  class Mapping
    attr_accessor :instance

    class << self
      def config=(config_str)
        @config = Aker::ConfigParser.new.parse(config_str)
      end

      attr_reader :config
    end

    def initialize(instance)
      raise 'Please update config/initializers/aker.rb with a config that describes the mapping.' if config.nil?
      @instance = instance
    end

    def update(attrs)
      val = true
      _each_model_and_setting_attrs_for(attrs) do |model, setting_attrs|
        val &&= set_value_for(model, setting_attrs)
      end
      val
    end

    def update!(attrs)
      raise 'Error while saving attributes' unless update(attrs)
      true
    end

    def attributes
      {}.tap do |obj|
        config[:updatable_attrs_from_ss_into_aker].each do |k|
          table_name = table_for_attr(k)
          value = get_value_for(
            model_for_table(table_name, k),
            aker_attr_name(table_name, k)
          )
          obj[k] = value
        end
      end
    end

    def config
      self.class.config
    end

    private

    def get_value_for(model, attr_name)
      return model.send(attr_name) unless model.nil?
      send(attr_name)
    end

    def set_value_for(model, setting_attrs)
      return model.update(setting_attrs) unless model.nil?
      setting_attrs.each_pair do |k, v|
        send(:"#{k}=", v)
      end
      true
    end

    def _each_model_and_setting_attrs_for(attrs)
      yielded_models = []
      attrs.keys.each do |attr_name|
        table_name = table_for_attr(attr_name)
        setting_attrs = attributes_for_table(table_name, attrs)
        model = model_for_table(table_name, attr_name)
        next if yielded_models.include?(model) || setting_attrs.empty?
        yielded_models.push(model)
        yield model, setting_attrs
      end
    end

    def model_for_table(_table_name, _attr_name)
      raise 'Not implemented'
    end

    def table_for_attr(attr_name)
      config[:map_ss_tables_with_aker].keys.each do |table_name|
        return table_name if config[:map_ss_tables_with_aker][table_name || :self].include?(attr_name.to_sym)
      end
      :self
    end

    def attributes_for_table(table_name, attrs)
      valid_keys = config[:map_ss_tables_with_aker][table_name] & config[:updatable_attrs_from_aker_into_ss]
      return {} unless valid_keys
      valid_attrs(table_name, valid_keys, attrs)
    end

    def aker_attr_name(table_name, field_name)
      return field_name unless config[:map_aker_with_ss_columns][table_name]
      config[:map_aker_with_ss_columns][table_name || :self][field_name] || field_name
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
