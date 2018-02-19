module Billing
  module Factory
    class Base
      include ActiveModel::Model

      NO_PROJECT_COST_CODE = 'S0755'.freeze

      attr_accessor :request
      attr_reader :billing_product

      validates :request, :passed_date, :billing_product, presence: true

      delegate :name, to: :billing_product, prefix: true

      def initialize(attributes = {})
        super

        self.passed_date = request
        self.billing_product = request
      end

      def passed_date=(request)
        return unless request.present?
        @passed_date = request.date_for_state('passed')
      end

      def passed_date
        return if @passed_date.nil?
        @passed_date.strftime('%Y%m%d')
      end

      def billing_product=(request)
        return unless request.present?
        @billing_product = request.billing_product
      end

      def project_cost_code(cost_code = nil)
        cost_code || NO_PROJECT_COST_CODE
      end

      # billing_product_code will be received from Agresso based on billing_product name
      def billing_product_code
        # this is been disabled because of Agresso performance issues
        # AgressoProduct.billing_product_code(billing_product.name)
      rescue
        nil
      end

      def billing_product_description
        billing_product.name
      end

      def units(*_args)
        100
      end

      def create!
        return unless valid?
        Billing::Item.create!(
          request: request,
          project_cost_code: project_cost_code,
          units: units,
          billing_product_code: billing_product_code,
          billing_product_name: billing_product_name,
          billing_product_description: billing_product_description,
          request_passed_date: passed_date
        )
      end
    end
  end
end
