# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube rack statuses
    class TubeRackStatus
      include ActiveModel::Model

      attr_accessor :barcode, :messages, :status

      validates :barcode, :messages, :status, presence: true

      validate :check_rack_barcode

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @tube_rack_status = ::TubeRackStatus.create!(barcode: barcode, status: status, messages: messages)
        end
        true
      end

      private

      def barcode_format
        Barcode.matching_barcode_format(barcode)
      end

      def check_rack_barcode
        if barcode_format.nil?
          error_message = "The tube rack barcode '#{barcode}' is not a recognised format."
          errors.add(:base, error_message)
          return false
        end
        true
      end
    end
  end
end
