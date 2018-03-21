module SampleManifestExcel
  module SpecialisedField
    module ValueRequired
      extend ActiveSupport::Concern

      included do
        validates_presence_of :value, message: "^#{name.demodulize.tableize.humanize.singularize} can't be blank"
      end
    end
  end
end
