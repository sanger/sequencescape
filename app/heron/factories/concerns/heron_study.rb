# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      # Tools to access the Heron study
      module HeronStudy
        HERON_STUDY = 6187

        def self.included(klass)
          klass.instance_eval do
            validates_presence_of :heron_study
          end
        end

        def heron_study
          @heron_study ||= Study.find(HERON_STUDY)
        end
      end
    end
  end
end
