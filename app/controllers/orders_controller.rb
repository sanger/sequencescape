class OrdersController < ApplicationController
  def destroy
    # Check for ajax request...
    if request.xhr?
      order = OrderPresenter.new(Order.find(params[:id]))
      order.destroy

      head :accepted
    end
  end

end

