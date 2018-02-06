module Aker
  class ProductsController < ApplicationController
    before_action :login_required, except: %i[show]

    def show
      render json: current_resource
    end

    def current_resource
      @current_resource ||= Aker::Product.find(params[:id]) if params[:id]
    end
  end
end
