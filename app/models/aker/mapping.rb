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
  # SS updates will occur on update() calls
  # Aker updates will happen on job completion, because the job message for the material is generated from
  # the attributes() method of this class.
  class Mapping
    class << self
      def config=(config_str)
        @config = Aker::ConfigParser.new.parse(config_str)
      end

      attr_reader :config
    end

    def update(attrs)
      val = true
      _each_model_and_setting_attrs_for(attrs.symbolize_keys) do |model, setting_attrs|
        val &&= update_model(model, setting_attrs)
      end
      val
    end

    def update!(attrs)
      raise 'Error while saving attributes' unless update(attrs)

      true
    end

    def attributes # rubocop:todo Metrics/MethodLength
      {}.tap do |obj|
        config[:updatable_columns_from_ss_into_aker].each do |table_name, column_names|
          model = model_for_table(table_name)
          column_names.each do |column_name|
            attribute_names_for_column(table_name, column_name).each do |attribute_name|
              raise 'Aker clash config problem' if obj[attribute_name]

              obj[attribute_name] = get_value_for(model, column_name)
            end
          end
        end
      end
    end

    def config
      self.class.config
    end

    # Gets a model instance and a hash of attributes and performs the update of fields on it
    # If no model is provided, it will suppose it is self
    def update_model(model, setting_attrs)
      return model.update(setting_attrs) unless model.nil?

      setting_attrs.each_pair { |k, v| send(:"#{k}=", v) }
      true
    end

    # Gets the value of an attribute name for a model
    def get_value_for(model, column_name)
      return model.send(column_name) unless model.nil?

      send(column_name)
    end

    # Given a table+column, it returns the list of Aker attribute names it maps to
    def attribute_names_for_column(table_name, column_name)
      config[:map_ss_columns_with_aker][table_name][column_name]
    end

    # Given a hash of attributes, it generates a list of table names that will be affected by the update
    def table_names_to_update(attrs)
      attrs.keys.map { |attr_name| table_names_for_attr(attr_name) }.flatten.uniq
    end

    # Given a hash of attributes to update, it will generate the list of model instances to update and the
    # corresponding specific attributes in each instance
    def _each_model_and_setting_attrs_for(attrs)
      table_names_to_update(attrs).each do |table_name|
        model = model_for_table(table_name)
        setting_attrs = mapped_setting_attributes_for_table(table_name, attrs)
        yield model, setting_attrs
      end
    end

    # Returns the model instance for the table name
    def model_for_table(_table_name)
      raise 'Not implemented'
    end

    # Given an attribute name, it returns all the available table names that this attribute can update
    def table_names_for_attr(attr_name)
      [].tap do |list|
        config[:map_ss_columns_with_aker].each do |table_name, column_object|
          list.push(table_name) if column_object.values.flatten.include?(attr_name) && list.exclude?(table_name)
        end
      end
    end

    # Given a table name and an attribute name, it returns a list of colunms of the table that corresponds to this
    # attribute
    #  Example:
    #    well.name         <= supplier_name
    #    well.supplier_name <= supplier_name
    # It would return [:name, :supplier_name]
    def columns_for_table_from_field(table_name, field_name)
      [].tap do |list|
        config[:map_ss_columns_with_aker][table_name].each do |column_name, field_names|
          list.push(column_name) if field_names.include?(field_name) && list.exclude?(column_name)
        end
      end
    end

    # Given a table name and a list of attributes, it returns a subset of attributes that will correspond
    # to the update of this table name
    def mapped_setting_attributes_for_table(table_name, attrs)
      {}.tap do |update_obj|
        attrs.each do |k, v|
          next unless config[:updatable_attrs_from_aker_into_ss].include?(k)

          columns_for_table_from_field(table_name, k).each { |column_name| update_obj[column_name] = v }
        end
      end
    end
  end
end
