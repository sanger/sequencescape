# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      module CoordinatesSupport
        LOCATION_REGEXP = /[A-Z][0-9]{0,1}[0-9]/.freeze        

        def unpad_coordinate(coordinate)
          return coordinate unless coordinate
  
          loc = coordinate.match(/(\w)(0*)(\d*)/)
          loc[1] + loc[3]
        end

        def coordinate_valid?(coordinate)
          return false if coordinate.blank?
  
          coordinate.match?(LOCATION_REGEXP)
        end
      end
    end
  end
end