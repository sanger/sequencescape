module Billing
  module Factory
    class Sequencing < Base
      attr_reader :aliquots

      validates :aliquots, presence: true

      def initialize(attributes = {})
        super

        self.aliquots = request
      end

      def aliquots=(request)
        return unless request.present?
        @aliquots = request.target_asset.try(:aliquots)
      end

      # TODO: create should be abstracted.
      def create!
        return unless valid?
        aliquots.by_project_cost_code.each do |project_cost_code, count|
          Billing::Item.create!(
            request: request,
            project_cost_code: project_cost_code,
            units: units(count, aliquots.length),
            fin_product_code: fin_product_code,
            fin_product_description: fin_product_description,
            request_passed_date: passed_date
          )
        end
      end

      def project_cost_code(cost_code)
        cost_code || super
      end

      def units(count, total)
        (count.to_f / total * 100).round
      end
    end
  end
end
