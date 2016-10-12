module SampleManifestExcel
  module MultiplexedLibraryTubeField

    class LibraryType < Base
      validates_presence_of :value
      validate :check_library_type_exists

    private

      def check_library_type_exists
        unless ::LibraryType.find_by_name(value).present?
          errors.add(:base, "could not find #{value} library type.")
        end
      end
    end
  end
end