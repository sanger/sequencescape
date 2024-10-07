# frozen_string_literal: true

module Heron
  module Factories
    module Concerns
      # A coordinate is the location identifier for a well or tube inside a plate or rack
      # This module adds validation and processing utilities for this type of identifiers.
      # Eg: A01, A1, F12, etc...
      module CoordinatesSupport
        LOCATION_REGEXP = /[A-Z][0-9]{0,1}[0-9]/

        def unpad_coordinate(coordinate)
          Map.strip_description(coordinate.to_s)
        end

        def coordinate_valid?(coordinate)
          return false if coordinate.blank?

          coordinate.match?(LOCATION_REGEXP)
        end
      end
    end
  end
end
