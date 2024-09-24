# frozen_string_literal: true

class Request
  module Traction
    class GridIon < CustomerRequest
      self.sequencing = true

      after_create :register_work_orders

      has_metadata as: Request do
        custom_attribute(:library_type, required: true, validator: true, selection: true)
        custom_attribute(:data_type, required: true, validator: true, selection: true)
      end

      validates :state, presence: true

      destroy_aasm

      def passed?
        state == 'passed'
      end

      # We've destroyed the stat_machine, but its validation remains.
      # Here we override it to allow custom states.
      def aasm_validate_states
        true
      end

      def register_work_orders
        # We go via order as we need to get a particular instance of submission
        return if order&.submission.nil?

        order.submission.register_callback(:once) { WorkOrder::Factory.new(order.submission).create_work_orders! }
      end
    end
  end
end
