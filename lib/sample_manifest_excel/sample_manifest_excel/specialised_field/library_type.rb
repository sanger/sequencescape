module SampleManifestExcel
  module SpecialisedField
    class LibraryType
      include Base
      include ValueRequired
      
      validate :check_library_type_exists


      def update(aliquot:)
        if valid? && aliquot.present?
          aliquot.library_type = value
          aliquot.save
        end
      end


    private

      def check_library_type_exists
        unless ::LibraryType.find_by(name: value).present?
          errors.add(:base, "could not find #{value} library type.")
        end
      end
    end
  end
end