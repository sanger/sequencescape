# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module Recipients
        def self.included(klass)
          klass.instance_eval do
            validate :check_recipients, if: :recipients
          end
        end

        def recipients
          return unless @params[recipients_key]
          return if errors.count.positive?

          @recipients ||= params_for_recipient.keys.each_with_object({}) do |coordinate, memo|
            memo[coordinate] = recipient_factory.new(params_for_recipient[coordinate])
          end
        end

        def check_recipients
          recipients.keys.each do |coordinate|
            recipient = recipients[coordinate]

            errors.add(:coordinate, 'Invalid coordinate format') unless coordinate_valid?(coordinate)

            next if recipient.valid?

            recipient.errors.each do |k, v|
              errors.add("Recipient at #{coordinate} #{k}", v)
            end
          end
        end

        def params_for_recipient
          return unless @params[recipients_key]

          @params_for_recipient ||= @params[recipients_key].keys.each_with_object({}) do |location, obj|
            obj[unpad_coordinate(location)] = @params.dig(recipients_key, location).except(:content)
          end
        end
      end
    end
  end
end
