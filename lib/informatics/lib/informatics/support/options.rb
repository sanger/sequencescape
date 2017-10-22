module Informatics
  module Support
    class Options
      attr_accessor :options

      def self.collect(*options)
        o = new
        o.options = options
        o
      end

      def options=(opt)
        if opt.is_a? Array
          opt = opt[0]
        end
        @options = opt
      end

      def options
        @options
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
        if @options.is_a? Hash
          o = @options
        elsif @options.is_a? Array
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
