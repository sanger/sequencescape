class HomeController < ApplicationController

  def index
    redirect_to :controller => 'pipelines', :action => 'index'
  end
  
end
