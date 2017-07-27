require_dependency 'request'

class Request
  module Traction
    class GridIon < CustomerRequest
      after_create :register_work_orders

      has_metadata as: Request do
        attribute(:library_type, required: true, validator: true, selection: true)
        attribute(:file_type,    required: true, validator: true, selection: true)
      end

      def register_work_orders
        # We go via order as we need to get a particular instance of submission
        return if order&.submission.nil?
        order.submission.register_callback(:once) do
          WorkOrder::Factory.new(order.submission).create_work_orders!
        end
      end
    end
  end
end
