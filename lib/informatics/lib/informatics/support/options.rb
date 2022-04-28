# frozen_string_literal: true
module Informatics
  module Support
    class Options # rubocop:todo Style/Documentation
      attr_reader :options

      def self.collect(*options)
        o = new
        o.options = options
        o
      end

      def options=(opt)
        opt = opt[0] if opt.is_a? Array
        @options = opt
      end

      def first_key
        incoming_options.keys.first
      end

      def first_value
        incoming_options.values.first
      end

      def key_is_present?(key)
        incoming_options.key? key
      end

      def value_for(key)
        incoming_options[key]
      end

      private

      def incoming_options
        o = nil
        case @options
        when Hash
          o = @options
        when Array
          o = @options[0]
        end
        o
      end

      def logger
        Rails.logger
      end
    end
  end
end
