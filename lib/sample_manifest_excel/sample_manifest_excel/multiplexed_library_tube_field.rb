module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class Base
      include SpecialisedField
    end

    module ValueToInteger
      def value
        @value.to_i if @value.present?
      end
    end

    Dir[File.join(File.dirname(__FILE__), 'multiplexed_library_tube_field', '*.rb')].each { |file| require file }

    SpecialisedField.create_field_list(self)
  end
end
