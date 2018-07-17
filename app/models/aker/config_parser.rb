# frozen_string_literal: true

module Aker
  # Translates config in initializers/aker.rb to a mapping object from Aker::Mapping
  # Parses expressions like:
  #
  #    sample_metadata.gender              <=   gender
  #      |
  #       -> It will update gender from Aker into sample_metadata.gender
  #
  #    sample_metadata.sample_common_name   =>   common_name
  #      |
  #       -> Update sample_common_name from sample_metadata into common_name in Aker
  #
  #     volume                             <=   volume
  #      |
  #       -> Update volume from Aker into Sequencescape using the setter method (volume=) in the mapping class
  #
  #    concentration                       <=>  concentration
  #      |
  #       -> Updates both ways, from Aker into Sequencescape and from Sequencescape into Aker
  #
  class ConfigParser
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
        next unless line.include?('=')
        tokens = tokenizer(line)
        unless tokens[:ss_model].nil?
          config[:map_ss_tables_with_aker][tokens[:ss_model]] = [] if config[:map_ss_tables_with_aker][tokens[:ss_model]].nil?
          config[:map_ss_tables_with_aker][tokens[:ss_model]].push(tokens[:aker_name])
        end
        config[:updatable_attrs_from_aker_into_ss].push(tokens[:aker_name]) if tokens[:aker_to_ss]
        config[:updatable_attrs_from_ss_into_aker].push(tokens[:aker_name]) if tokens[:ss_to_aker]
        next unless tokens[:ss_name] != tokens[:aker_name]
        config[:map_aker_with_ss_columns][tokens[:ss_model]] = {} if config[:map_aker_with_ss_columns][tokens[:ss_model]].nil?
        config[:map_aker_with_ss_columns][tokens[:ss_model]][tokens[:aker_name]] = tokens[:ss_name]
      end
      config
    end

    def tokenizer(str)
      list = str.split('=').map { |s| s.gsub(/[<=> ]/, '') }
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
