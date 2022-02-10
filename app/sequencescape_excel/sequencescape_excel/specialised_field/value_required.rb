# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ValueRequired
    module ValueRequired
      extend ActiveSupport::Concern

      included { validates :value, presence: true }

      class_methods do
        def human_attribute_name(att, options = {})
          if att.to_sym == :value
            name.demodulize.tableize.humanize.singularize
          else
            super
          end
        end
      end
    end
  end
end
