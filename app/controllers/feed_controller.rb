class FeedController < ApplicationController

  layout nil

  def updates
    render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return
  end

end
