# frozen_string_literal: true

# Takes form input from {PhiXesController#show} and generates a PhiX {LibraryTube} using
# the factory {PhiX::Stock}
class PhiX::StocksController < ApplicationController
  def create
    @stock = PhiX::Stock.new(phi_x_stock_params)
    if @stock.save
      @stocks = @stock.created_stocks
      render :show
    else
      @stocks = []
      @tag_option_names = PhiX.tag_option_names
      @study_names = PhiX.studies.for_select_association
      render :new
    end
  end

  private

  def phi_x_stock_params
    params.require(:phi_x_stock).permit(:name, :tags, :concentration, :number, :study_id)
  end
end
