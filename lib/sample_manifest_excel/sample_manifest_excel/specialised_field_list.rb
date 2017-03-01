module SampleManifestExcel
  class SpecialisedFieldList
    include Enumerable

    attr_reader :specialised_fields

    def initialize
      @specialised_fields = create_specialised_fields
    end

    def each(&block)
      specialised_fields.each(&block)
    end

    def find(key)
      specialised_fields[key]
    end

  private

    def create_specialised_fields
      {}.tap do |specialised_fields|
        SampleManifestExcel::SpecialisedField.constants.each do |specialised_field|
          const = "SampleManifestExcel::SpecialisedField::#{specialised_field}".constantize
          if const.is_a?(Class)
            specialised_fields[specialised_field.to_s.underscore.to_sym] = const
          end
        end
      end
    end
  end
end
