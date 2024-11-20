# frozen_string_literal: true
module Accession
  # A tag relates to a sample attribute.
  # It provides all of the relevant information for that attribute
  # i.e. which service it is required for and which
  # groups it will be assigned to in the xml.
  class Tag
    include ActiveModel::Model
    include Accession::Equality

    attr_accessor :services, :value, :name, :groups, :ebi_name, :class_name

    validates_presence_of :name, :groups

    DEFAULT_ATTRIBUTES = { services: [] }.freeze

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
      %i[services value name groups ebi_name]
    end

    # Some helper methods for displaying information from tags
    module HelperTagValue
      NOT_COLLECTED = 'not collected'
      NOT_PROVIDED = 'not provided'
      RESTRICTED_ACCESS = 'restricted access'
      NOT_APPLICABLE_CONTROL_SAMPLE = 'not applicable: control sample'
      NOT_APPLICABLE_SAMPLE_GROUP = 'not applicable: sample group'
      MISSING_SYNTHETIC_CONSTRUCT = 'missing: synthetic construct'
      MISSING_LAB_STOCK = 'missing: lab stock'
      MISING_THIRD_PARTY_DATA = 'missing: third party data'
      MISSING_DATA_AGGREEMENT_PRE2023 = 'missing: data agreement established pre-2023'
      MISSING_ENDANGERED_SPECIES = 'missing: endangered species'
      MISSING_HUMAN_IDENTIFIABLE = 'missing: human-identifiable'
      MISSING_CONTROL_SAMPLE = 'missing: control sample'
      MISSING_SAMPLE_GROUP = 'missing: sample group'

      OTHER_DEFAULT_SETTINGS = [
        NOT_COLLECTED,
        NOT_PROVIDED,
        RESTRICTED_ACCESS,
        NOT_APPLICABLE_CONTROL_SAMPLE,
        NOT_APPLICABLE_SAMPLE_GROUP,
        MISSING_SYNTHETIC_CONSTRUCT,
        MISSING_LAB_STOCK,
        MISING_THIRD_PARTY_DATA,
        MISSING_DATA_AGGREEMENT_PRE2023,
        MISSING_ENDANGERED_SPECIES,
        MISSING_HUMAN_IDENTIFIABLE,
        MISSING_CONTROL_SAMPLE,
        MISSING_SAMPLE_GROUP
      ].freeze

      def incorrect_format_value
        NOT_PROVIDED
      end

      def value_for(record, key)
        record.send(key)
      end
    end
    include HelperTagValue
  end

  # Value serialization for country of origin in accessioning XML generation
  # It will return a valid country of origin or 'not collected' if nothing provided or invalid
  # It also allow other config settings for the XML service like the list defined inside OTHER_DEFAULT_SETTINGS
  class TagCountryOfOrigin < Tag
    def value_for(record, key)
      val = record.send(key)
      return val if OTHER_DEFAULT_SETTINGS.include?(val)
      return incorrect_format_value unless Insdc::Country.find_by(name: val)
      val
    end
  end

  # Value serialization for collection date in accessioning XML generation
  # It will return a valid collection date or 'not collected' if nothing provided or invalid
  # It also allow other config settings for the XML service like the list defined inside OTHER_DEFAULT_SETTINGS
  # NB: this regexp is defined in <https://www.ebi.ac.uk/ena/browser/api/xml/ERC000011>
  class TagCollectionDate < Tag
    # rubocop:disable Layout/LineLength
    REGEXP =
      %r{(^[12][0-9]{3}(-(0[1-9]|1[0-2])(-(0[1-9]|[12][0-9]|3[01])(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?(/[0-9]{4}(-[0-9]{2}(-[0-9]{2}(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?)?$)}

    # rubocop:enable Layout/LineLength

    def value_for(record, key)
      val = record.send(key)
      return val if OTHER_DEFAULT_SETTINGS.include?(val)
      return incorrect_format_value unless REGEXP.match?(val)
      val
    end
  end
end
