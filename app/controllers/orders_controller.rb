# frozen_string_literal: true
class OrdersController < ApplicationController
  def update
    @order = Order.find(params[:id])
    @order.add_comment(params[:comments], current_user) unless params[:comments].nil?

    redirect_to @order.submission
  end

  def destroy
    # Check for ajax request...
    if request.xhr?
      Order.find(params[:id]).destroy
      head :accepted
    end
  end
end
