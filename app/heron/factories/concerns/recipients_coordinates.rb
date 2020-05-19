# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module RecipientsCoordinates
        def self.included(klass)
          klass.instance_eval do
            validate :check_recipient_coordinates            
          end
        end

        def check_recipient_coordinates
          return unless @params[recipients_key]
          @params[recipients_key].keys.select{|k| !coordinate_valid?(k) }.each do |k|
            errors.add(:coordinate, "The location \"#{k}\" has an invalid format")
          end
        end
      end
    end
  end
end
