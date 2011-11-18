class Api::OrdersController < Api::BaseController
  self.model_class = Order

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [:index ]

private

  def prepare_list_context
    case
    when params[:submission_id].present?
      @context = ::Submission.find(params[:submission_id]).orders
    else
      @context = ::Order.including_associations_for_json
    end
  end
end
