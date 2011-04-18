module Snp
  def self.included(base)
    config = YAML.load(ERB.new(File.read(File.dirname(__FILE__) + "/../config/database.yml")).result)
    base.send(:establish_connection, config["#{Rails.env}_snp"])

    base.class_eval do
      def self.next_value
        self.connection.next_sequence_value(self.sequence_name)
      end
    end
  end
end
