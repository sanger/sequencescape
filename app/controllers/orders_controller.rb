class OrdersController < ApplicationController
  def destroy
    # Check for ajax request...
    if request.xhr?
      Order.find(params[:id]).destroy

      head :accepted
    end
  end

end

