module ActiveRecord::StringSanitizer
  def self.extended(base)
    base.instance_eval do
      def squish(str)
        str.gsub(/\s+/, " ")
      end

      def squishify(*names)
        line = __LINE__ + 1
        class_eval(%Q{
          before_create do |record|
            names.each do |name|
              value = record.send(name)
              record.send(name.to_s + '=', squish(value)) if value.is_a? String
            end
          end
          }, __FILE__, line)
      end
    end
  end
end

class ActiveRecord::Base
  extend ActiveRecord::StringSanitizer
end
