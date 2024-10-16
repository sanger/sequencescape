# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # Validates the object under @params[recipients_key] to check that all keys
      # are valid coordinates, otherwise it will add the errors to the active model instance
      module RecipientsCoordinates
        def self.included(klass)
          klass.instance_eval { validate :check_recipient_coordinates }
        end

        def check_recipient_coordinates
          return unless @params[recipients_key]

          @params[recipients_key]
            .keys
            .reject { |k| coordinate_valid?(k) }
            .each { |k| errors.add(:coordinate, "The location \"#{k}\" has an invalid format") }
        end
      end
    end
  end
end
