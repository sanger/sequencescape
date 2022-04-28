# frozen_string_literal: true
module Request::CustomerResponsibility # rubocop:todo Style/Documentation
  def self.included(base)
    base::Metadata.class_eval do
      custom_attribute(:customer_accepts_responsibility, boolean: true)
      validate :customer_can_accept_responsibility?, if: :customer_accepts_responsibility_changed?, on: :update

      def customer_can_accept_responsibility?
        return true unless request.try(:failed?)

        errors.add(:customer_accepts_responsibility, 'can not be changed once a request is failed.')
        raise ActiveRecord::RecordInvalid, self
      end
    end
  end
end
