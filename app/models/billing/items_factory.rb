module Billing
  # Takes request as an argument
  # Valid if it has request, request.target_asset has aliquots, request is passed, request has fin_product
  # Creates billing items based on amount of aliquots related to different project_cost_codes
  class ItemsFactory
    include ActiveModel::Model

    attr_accessor :request, :aliquots, :passed_date # fin_product to be added

    validates :request, :aliquots, :passed_date, presence: true # fin_product to be added

    def initialize(attr = {})
      super
      @aliquots = request.target_asset.try(:aliquots) if request.present?
      @passed_date = request.date_for_state('passed') if request.present?
      # @fin_product = request.fin_product if request.present?
    end

    def create_billing_items
      aliquots.by_project_cost_code.each do |project_cost_code, count|
        Billing::Item.create!(
          request: request,
          project_cost_code: (project_cost_code || no_project_cost_code),
          units: number_of_units(count, aliquots.length),
          fin_product_code: fin_product_code,
          fin_product_description: fin_product_description,
          request_passed_date: passed_date.strftime('%Y%m%d')
        )
      end
    end

    private

    def number_of_units(count, total)
      (count.to_f / total * 100).round
    end

    def no_project_cost_code
      'S0755'
    end

    # fin_product_code will be received from Agresso based on fin_product name
    def fin_product_code
      ''
    end

    def fin_product_description
      request.request_type.name # should be fin_product.description ?
    end
  end
end
