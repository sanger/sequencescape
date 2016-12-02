module Accession
  class Tag
    include ActiveModel::Validations
    include SampleManifestExcel::HashAttributes

    set_attributes :services, :array_express, :value, :name, :parent, defaults: {services: []}

    validates_presence_of :name, :parent

    def initialize(attributes = {})
      create_attributes(attributes)
    end

    def services=(services)
      @services = Array(services)
    end

    def required_for?(service)
      services.include? service
    end

    def array_express?
      array_express
    end

    def add_value(value)
      @value = value
      self
    end

  end
end