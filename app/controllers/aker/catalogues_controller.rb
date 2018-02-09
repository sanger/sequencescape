module Aker
  class CataloguesController < ApplicationController
    before_action :login_required, except: %i[show index]

    def index
      render json: Aker::Catalogue.all
    end

    def show
      render json: current_resource
    end

    def current_resource
      @current_resource ||= Aker::Catalogue.find(params[:id]) if params[:id]
    end
  end
end
