# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module Contents
        def self.included(klass)
          klass.instance_eval do
            validate :check_contents, if: :contents
          end
        end

        def contents
          return unless @params[recipients_key]
          return if errors.count.positive?

          @contents ||= ::Heron::Factories::Contents.new(params_for_contents, @params[:study_uuid])
        end

        def check_contents
          return if contents.valid?

          errors.add(:contents, contents.errors.full_messages)
        end

        def params_for_contents
          return unless @params[recipients_key]

          @params_for_contents ||= @params[recipients_key].keys.each_with_object({}) do |location, obj|
            obj[unpad_coordinate(location)] = @params.dig(recipients_key, location, :content)
          end
        end
      end
    end
  end
end
