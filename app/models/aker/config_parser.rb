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
        map_ss_columns_with_aker: {
        },

        # Aker attributes allowed to update from Aker into SS
        updatable_attrs_from_aker_into_ss: [],

        # Sequencescape models with columns allowed to update from SS into Aker
        updatable_columns_from_ss_into_aker: {}
      }
    end

    def parse(description_text)
      description_text.split("\n").each do |line|
        next unless line.include?('=')

        token = tokenizer(line)
        __parse_map_ss_columns_with_aker(token)
        __parse_updatable_attrs_from_aker_into_ss(token)
        __parse_updatable_columns_from_ss_into_aker(token)
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

      {
        # Attribute name in Aker
        aker_name: aker_name,
        # Left hand side string
        ss: ss,
        # Sequencescape mapping model
        ss_model: ss_model,
        # Sequencescape mapping column
        ss_name: ss_name,
        # Boolean specifying update from SS to Aker
        ss_to_aker: ss_to_aker,
        # Boolean specifying update from Aker into SS
        aker_to_ss: aker_to_ss
      }
    end

    private

    def __parse_map_ss_columns_with_aker(token)
      return if token[:ss_model].nil?

      config[:map_ss_columns_with_aker][token[:ss_model]] = {} if config[:map_ss_columns_with_aker][token[:ss_model]].nil?
      config[:map_ss_columns_with_aker][token[:ss_model]][token[:ss_name]] = [] if config[:map_ss_columns_with_aker][token[:ss_model]][token[:ss_name]].nil?

      attr_name = token[:aker_name]

      config[:map_ss_columns_with_aker][token[:ss_model]][token[:ss_name]].push(attr_name) unless config[:map_ss_columns_with_aker][token[:ss_model]][token[:ss_name]].include?(attr_name)
    end

    def __parse_updatable_attrs_from_aker_into_ss(token)
      return unless token[:aker_to_ss]

      config[:updatable_attrs_from_aker_into_ss].push(token[:aker_name]) unless config[:updatable_attrs_from_aker_into_ss].include?(token[:aker_name])
    end

    def __parse_updatable_columns_from_ss_into_aker(token)
      return unless token[:ss_to_aker]

      config[:updatable_columns_from_ss_into_aker][token[:ss_model]] = [] if config[:updatable_columns_from_ss_into_aker][token[:ss_model]].nil?
      config[:updatable_columns_from_ss_into_aker][token[:ss_model]].push(token[:ss_name])
    end
  end
end
