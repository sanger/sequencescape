module SampleManifestExcel
  module SpecialisedField

    extend ActiveSupport::Concern

    mattr_accessor :subclasses, instance_writer: false
    self.subclasses = [:sample_field, :multiplexed_library_tube_field]

    self.subclasses.each do |subclass|
      define_method "#{subclass}?" do
        self.class.to_s.include?(subclass.to_s.classify)
      end
    end

    included do
      include ActiveModel::Validations
      attr_reader :value
    end

    def type
      @type ||= self.class.name.demodulize.underscore.to_sym
    end

    def update(attributes = {})
      if attributes[:row].present?
        @value = attributes[:row].value(type)
      end
      self
    end

    def value_present?
      value.present?
    end

    def self.create_field_list(mod)
      mod::Base.class_exec do
        cattr_accessor :fields, instance_writer: false
        self.fields = {}.tap do |f|
          subclasses.each do |subclass|
            f[subclass.name.demodulize.underscore.to_sym] = subclass
          end
        end
      end
    end

  end
end