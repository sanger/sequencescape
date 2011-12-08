class OrdersControllers < ApplicationController
  def destroy
    #wrap this in a xhr check.
    Order.find(params[:id]).destroy


    # send back some json to say it was a sucess
  end
end

