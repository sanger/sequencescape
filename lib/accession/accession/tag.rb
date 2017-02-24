module Accession
  # A tag relates to a sample attribute.
  # It provides all of the relevant information for that attribute
  # i.e. which service it is required for and which
  # groups it will be assigned to in the xml.
  class Tag
    include ActiveModel::Model
    include Accession::Equality

    attr_accessor :services, :value, :name, :groups, :ebi_name

    validates_presence_of :name, :groups

    DEFAULT_ATTRIBUTES = { services: [] }

    def initialize(attributes = {})
      super(DEFAULT_ATTRIBUTES.merge(attributes))
    end

    def services=(services)
      @services = Array(services)
    end

    def value=(value)
      @value = value.to_s
    end

    def required_for?(service)
      services.include? service.provider
    end

    def array_express?
      array_express
    end

    def sample_name?
      sample_name
    end

    def sample_attributes?
      sample_attributes
    end

    def add_value(value)
      self.value = value
      self
    end

    def label
      (ebi_name || name).to_s.upcase
    end

    def array_express_label
      "ArrayExpress-#{label}"
    end

    def attributes
      [:services, :value, :name, :groups, :ebi_name]
    end
  end
end
