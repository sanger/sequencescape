# frozen_string_literal: true
# Base class to control generating XML for accessioning with the ENA or EGA
# @see AccessionService
class Accessionable::Base
  InvalidData = Class.new(AccessionService::AccessionServiceError)
  attr_reader :accession_number, :name, :date, :date_short

  def initialize(accession_number)
    @accession_number = accession_number

    time_now = Time.zone.now
    @date = time_now.strftime('%Y-%m-%dT%H:%M:%SZ')
    @date_short = time_now.strftime('%Y-%m-%d')
  end

  def errors
    []
  end

  def xml
    raise NotImplementedError, 'abstract method'
  end

  def center_name
    AccessionService::CENTER_NAME
  end

  def schema_type
    # raise NotImplementedError, "abstract method"
    self.class.name.split('::').last.downcase
  end

  def alias
    "#{name.gsub(/[^a-z\d]/i, '_')}-sc-#{accessionable_id}"
  end

  def file_name
    "#{self.alias}-#{date}.#{schema_type}.xml"
  end

  def extract_accession_number(xmldoc)
    element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}"]
    accession_number = element && element.attributes['accession']
  end

  def extract_array_express_accession_number(xmldoc)
    element = xmldoc.root.elements["/RECEIPT/#{schema_type.upcase}/EXT_ID[@type='ArrayExpress']"]
    accession_number = element && element.attributes['accession']
  end

  def update_accession_number!(_user, _accession_number)
    raise AccessionService::NotImplementedError, 'abstract method'
  end

  def update_array_express_accession_number!(accession_number)
  end

  def accessionable_id
    raise AccessionService::NotImplementError, 'abstract method'
  end

  def released?
    # Return false by default. Overidden by sample.
    false
  end

  def label_scope
    @label_scope ||= "metadata.#{self.class.name.split('::').last.downcase}.metadata"
  end

  class Tag
    attr_reader :value

    # Value serialization for accessioning XML generation
    # It will return the same value without any changes and it applies
    # to all tags
    class FieldSerializer
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

      def value_for(value)
        value
      end

      def applies_to?(_name)
        true
      end

      def incorrect_format_value
        NOT_PROVIDED
      end
    end

    # Value serialization for country of origin in accessioning XML generation
    # It will return a valid country of origin or 'not collected' if nothing provided or invalid
    # It also allow other config settings for the XML service like the list defined inside OTHER_DEFAULT_SETTINGS
    class FieldCountryOfOrigin < FieldSerializer
      def value_for(value)
        return value if OTHER_DEFAULT_SETTINGS.include?(value)
        return incorrect_format_value unless Insdc::Country.find_by(name: value)

        value
      end

      def applies_to?(name)
        name == :country_of_origin
      end
    end

    # Value serialization for collection date in accessioning XML generation
    # It will return a valid collection date or 'not collected' if nothing provided or invalid
    # It also allow other config settings for the XML service like the list defined inside OTHER_DEFAULT_SETTINGS
    # NB: this regexp is defined in <https://www.ebi.ac.uk/ena/browser/api/xml/ERC000011>
    class FieldCollectionDate < FieldSerializer
      # rubocop:disable Layout/LineLength
      REGEXP =
        %r{(^[12][0-9]{3}(-(0[1-9]|1[0-2])(-(0[1-9]|[12][0-9]|3[01])(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?(/[0-9]{4}(-[0-9]{2}(-[0-9]{2}(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?)?$)}

      # rubocop:enable Layout/LineLength

      def value_for(value)
        return value if OTHER_DEFAULT_SETTINGS.include?(value)
        return incorrect_format_value unless REGEXP.match?(value)

        value
      end

      def applies_to?(name)
        name == :date_of_sample_collection
      end
    end

    SERIALIZERS = [FieldCountryOfOrigin.new, FieldCollectionDate.new, FieldSerializer.new].freeze

    def initialize(label_scope, name, value, downcase = false)
      @name = name
      @value = field_serializer_for(name).value_for(downcase && value ? value.downcase : value)
      @scope = label_scope
    end

    def label
      accessioning_tag = I18n.exists?("#{@scope}.#{@name}.accessioning_tag")

      # check for field override for when ebi name is different from sanger name
      # NB. replace any underscores with spaces and ensure in lowercase
      return I18n.t("#{@scope}.#{@name}.accessioning_tag").tr('_', ' ').downcase if accessioning_tag

      # For the rest the ebi name is the same as the sanger name
      I18n.t("#{@scope}.#{@name}.label").tr('_', ' ').downcase
    end

    def field_serializer_for(name)
      SERIALIZERS.detect { |s| s.applies_to?(name) }
    end

    def build(xml)
      xml.TAG label
      xml.VALUE value
    end
  end
end
