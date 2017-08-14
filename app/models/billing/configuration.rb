module Billing
  # used to create fields from yml file and store them in memory (see config/initializers/billing.rb)
  class Configuration
    attr_reader :fields

    def fields=(fields)
      @fields = FieldsList.new(fields).freeze
    end

    def load_file(folder, filename)
      YAML.load_file(Rails.root.join(folder, "#{filename}.yml")).with_indifferent_access
    end
  end
end
