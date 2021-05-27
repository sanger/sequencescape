# Extends ApplicationRecord and provides squishify configuration
# to remove duplicated whitespace from strings
module Squishify
  def self.extended(base) # rubocop:todo Metrics/MethodLength
    base.instance_eval do
      def squishify(*names)
        class_eval do
          before_validation do |record|
            names.each do |name|
              value = record.send(name)
              record.send(name.to_s + '=', value.squish) if value.is_a? String
            end
          end
        end
      end
    end
  end
end
