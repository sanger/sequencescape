module Billing
  module Factory
    class Base
      include ActiveModel::Model

      NO_PROJECT_COST_CODE = 'S0755'.freeze

      attr_accessor :request

      validates :request, :passed_date, presence: true

      def initialize(attributes = {})
        super

        self.passed_date = request
      end

      def passed_date=(request)
        return unless request.present?
        @passed_date = request.date_for_state('passed')
      end

      def passed_date
        return if @passed_date.nil?
        @passed_date.strftime('%Y%m%d')
      end

      def project_cost_code
        NO_PROJECT_COST_CODE
      end

      # fin_product_code will be received from Agresso based on fin_product name
      def fin_product_code
        ''
      end

      def fin_product_description
        request.request_type.name # should be fin_product.description ?
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
          fin_product_code: fin_product_code,
          fin_product_description: fin_product_description,
          request_passed_date: passed_date
        )
      end
    end
  end
end
