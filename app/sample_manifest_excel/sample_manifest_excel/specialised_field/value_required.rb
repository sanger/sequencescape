# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # ValueRequired
    module ValueRequired
      extend ActiveSupport::Concern

      included do
        validates_presence_of :value, message: "^#{name.demodulize.tableize.humanize.singularize} can't be blank"
      end
    end
  end
end
