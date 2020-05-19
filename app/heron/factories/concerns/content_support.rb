# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module ContentSupport
        def self.included(klass)
          klass.instance_eval do
            validate :check_content, if: :content
          end
        end

        def content
          return unless @params[recipients_key]

          @content ||= ::Heron::Factories::Content.new(params_for_content, @params[:study_uuid])
        end

        def check_content
          return if content.valid?

          errors.add(:content, content.errors.full_messages)
        end

        def params_for_container
          return unless @params[recipients_key]

          @params_for_container ||= @params[recipients_key].keys.each_with_object({}) do |location, obj|
            obj[unpad_coordinate(location)] = @params.dig(recipients_key, location).except(:content)
          end
        end

        def params_for_content
          return unless @params[recipients_key]

          @params_for_content ||= @params[recipients_key].keys.each_with_object({}) do |location, obj|
            obj[unpad_coordinate(location)] = @params.dig(recipients_key, location, :content)
          end
        end
      end
    end
  end
end
