# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015,2016 Genome Research Ltd.

class OrdersController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  def destroy
    # Check for ajax request...
    if request.xhr?
      Order.find(params[:id]).destroy
      head :accepted
    end
  end

  def update
    @order = Order.find(params[:id])
    @order.add_comment(params[:comments], current_user) unless params[:comments].nil?

    redirect_to @order.submission
  end
end
