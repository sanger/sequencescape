module SampleManifestExcel
  module SpecialisedField
    module ValueRequired
      extend ActiveSupport::Concern

      included do
        validates_presence_of :value
      end
    end
  end
end