class OrdersController < ApplicationController
  def destroy
    # Check for ajax request...
    if request.xhr?
      order_model = Order.find(params[:id])
      order = OrderPresenter.new(order_model)
      order_model.destroy

      head :accepted
    end
  end

end

