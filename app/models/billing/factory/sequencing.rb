module Billing
  module Factory
    class Sequencing < Base # rubocop:todo Style/Documentation
      attr_reader :aliquots

      validates :aliquots, presence: true

      def initialize(attributes = {})
        super
        self.aliquots = request
      end

      def aliquots=(request)
        return if request.blank?

        @aliquots = request.target_asset.try(:aliquots)
      end

      # TODO: create should be abstracted.
      def create!
        return unless valid?

        aliquots.count_by_project_cost_code.each do |cost_code, count|
          Billing::Item.create!(
            request: request,
            project_cost_code: project_cost_code(cost_code),
            units: units(count, aliquots.length),
            billing_product_code: billing_product_code,
            billing_product_description: billing_product_description,
            billing_product_name: billing_product_name,
            request_passed_date: passed_date
          )
        end
      end

      def units(count, total)
        (count.to_f / total * 100).round
      end
    end
  end
end
