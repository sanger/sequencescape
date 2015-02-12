#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2014 Genome Research Ltd.
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

  def update
    @order = Order.find(params[:id])
    @order.add_comment(params[:comments], current_user) unless params[:comments].nil?

    redirect_to @order.submission
  end

end

