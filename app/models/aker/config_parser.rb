module Aker
  class ConfigParser
# This config setting defines the mapping between models and attributes in Sequencescape and
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
    attr_accessor :config

    def initialize(config = nil)
      @config = config || initial_config
    end

    def initial_config
      {
        # Maps SS models with Aker attributes
        map_ss_tables_with_aker: {
        },

        # Maps SS column names from models with Aker attributes (if the name is different)
        map_aker_with_ss_columns: {
        },

        # Aker attributes allowed to update from Aker into SS
        updatable_attrs_from_aker_into_ss: [],

        # Aker attributes allowed to update from SS into Aker
        updatable_attrs_from_ss_into_aker: []
      }
    end

    def parse(description_text)
      description_text.split("\n").each do |line|
        next unless line.include?("=")
        tokens = tokenizer(line)
        unless tokens[:ss_model].nil?
          if config[:map_ss_tables_with_aker][tokens[:ss_model]].nil?
            config[:map_ss_tables_with_aker][tokens[:ss_model]] = []
          end
          config[:map_ss_tables_with_aker][tokens[:ss_model]].push(tokens[:aker_name])
        end
        if tokens[:aker_to_ss]
          config[:updatable_attrs_from_aker_into_ss].push(tokens[:aker_name])
        end
        if tokens[:ss_to_aker]
          config[:updatable_attrs_from_ss_into_aker].push(tokens[:aker_name])
        end
        if tokens[:ss_name] != tokens[:aker_name]
          if config[:map_aker_with_ss_columns][tokens[:ss_model]].nil?
            config[:map_aker_with_ss_columns][tokens[:ss_model]] = {}
          end
          config[:map_aker_with_ss_columns][tokens[:ss_model]][tokens[:aker_name]] = tokens[:ss_name] 
        end
      end
      config
    end

    def tokenizer(str)
      list = str.split('=').map{|s| s.gsub(/[<=> ]/, '')}
      ss = list[0]
      aker_name = list[1].to_sym
      ss_to_aker = str.include?('=>')
      aker_to_ss = str.include?('<=')
      ss_name, ss_model = ss.split('.').reverse.map(&:to_sym)
      ss_model = :self if ss_model.nil?

      { aker_name: aker_name, ss: ss, ss_model: ss_model, 
        ss_name: ss_name, ss_to_aker: ss_to_aker, aker_to_ss: aker_to_ss }
    end

  end
end