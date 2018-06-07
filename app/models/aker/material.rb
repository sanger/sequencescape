#
# This class synchronizes the data between Aker and SS by mapping tables and columns in SS with
# property names from Aker materials service
#
# To be able to update between Aker and SS we need to map the Aker field names with the corresponding SS
# tables and columns. To do so:
#
# 1. Add the field name from aker as a value inside the corresponding list for the key with the SS table name 
#     in MAP_SS_TABLES_WITH_AKER
# 2. Add the field name from aker as a key linked with a column name for SS in MAP_AKER_WITH_SS_COLUMNS
#
# After this, if we want to update a new property from Aker into SS models we have to add the field name 
# from aker inside the list UPDATABLE_ATTRS_FROM_AKER_INTO_SS.
# 
# If we want to update a change in SS into the properties of Aker in the material service we have to add 
# the field name from aker inside the list UPDATABLE_ATTRS_FROM_SS_INTO_AKER.
# 
# SS updates will occur on update_attributes() calls
# Aker updates will happen on job completion, because the job message for the material is generated from
# the attributes() method of this class.
module Aker
  class Material
    # Maps SS models with Aker attributes
    MAP_SS_TABLES_WITH_AKER = {
      samples: [],
      sample_metadata: [:gender, :donor_id, :phenotype, :common_name],
      well_attribute: [:volume, :concentration]
    }

    # Maps SS column names with Aker attributes (if the name is different)
    MAP_AKER_WITH_SS_COLUMNS = {
      volume: :measured_volume,
      common_name: :sample_common_name
    }

    # Aker attributes allowed to update from Aker into SS
    UPDATABLE_ATTRS_FROM_AKER_INTO_SS = [
      :gender, :donor_id, :phenotype, :common_name,
      :volume, :concentration
    ]

    # Aker attributes allowed to update from SS into Aker
    UPDATABLE_ATTRS_FROM_SS_INTO_AKER = [:volume, :concentration]

    attr_accessor :sample

    def initialize(sample)
      @sample = sample
    end

    def update_attributes(attrs)
      attrs.keys.each do |attr_name|
        table_name = table_for_attr(attr_name)
        setting_attrs = attributes_for_table(table_name, attrs)
        model = model_for_table(table_name)
        model.update_attributes(setting_attrs)
      end
    end

    def attributes
      obj = {"_id": sample.name}

      UPDATABLE_ATTRS_FROM_SS_INTO_AKER.each do |k|
        model =  model_for_table(k)
        if model
          attr_name = aker_attr_name(k)
          value = model.send(attr_name)
        end
        if value
          obj[k] = value
        end
      end

      obj
    end

    private

    def table_for_attr(attr_name)
      MAP_SS_TABLES_WITH_AKER.keys.each do |table_name|
        return table_name if MAP_SS_TABLES_WITH_AKER[table_name].include?(attr_name)
      end
    end

    def model_for_table(table_name)
      table_name = table_name
      return sample if table_name == :samples
      return sample.sample_metadata if table_name == :sample_metadata
      return sample.container.asset.well_attribute if table_name == :well_attribute
    end

    def attributes_for_table(table_name, attrs)
      valid_attrs_into_ss(MAP_SS_TABLES_WITH_AKER[table_name], attrs)
    end

    def aker_attr_name(field_name)
      MAP_AKER_WITH_SS_COLUMNS[field_name] || field_name
    end

    def valid_attrs_into_ss(valid_list, attrs)
      valid_attrs_into(UPDATABLE_ATTRS_FROM_AKER_INTO_SS, valid_list, attrs)
    end

    def valid_attrs_into_aker(valid_list, attrs)
      valid_attrs_into(UPDATABLE_ATTRS_FROM_SS_INTO_AKER, valid_list, attrs)
    end

    def valid_attrs_into(updatable_list, valid_list, attrs)
      check_list = updatable_list & valid_list
      obj = attrs.select{|k,v| check_list.include?(k)}
      memo = {}
      obj.each_pair do |k,v|
        memo[aker_attr_name(k)] = v
      end
      memo
    end

  end
end