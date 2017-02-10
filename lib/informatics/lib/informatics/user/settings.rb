module Informatics
  module User
    class Settings
      include Informatics::Globals

      attr_accessor :keys

      def self.available
        d = new
        yield d
        @@defaults = d
      end

      def add(key, value)
        unless @keys
          @keys = {}
        end
        @keys[key] = value
      end

      def method_missing(m, *_a)
        @keys.each do |key, value|
          if key.to_s == m.to_s
            return value
          end
        end
        raise NoMethodError, m.to_s
      end
    end
  end
end
