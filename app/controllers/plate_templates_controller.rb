# frozen_string_literal: true
class PlateTemplatesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource

  def index
    @patterns = PlateTemplate.paginate(page: params[:page], per_page: 50)
  end

  def new
    @plate_rows = params[:rows].to_i
    @plate_cols = params[:cols].to_i
    @plate_rows = Map::Coordinate.plate_length(96) if @plate_rows == 0
    @plate_cols = Map::Coordinate.plate_width(96) if @plate_cols == 0

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @pattern = PlateTemplate.find(params[:id])
    @plate_rows = Map::Coordinate.plate_length(@pattern.size)
    @plate_cols = Map::Coordinate.plate_width(@pattern.size)
  end

  def create # rubocop:todo Metrics/AbcSize
    if params[:name].blank?
      flash[:error] = 'Please enter a name'
      redirect_to new_plate_template_path
      return
    end

    pattern = PlateTemplate.new
    pattern.update_params!(
      name: params[:name],
      user_id: current_user.id,
      wells: params[:empty_well],
      rows: params[:rows],
      cols: params[:cols]
    )
    flash[:notice] = 'Template saved'
    redirect_to plate_templates_path
  end

  def update # rubocop:todo Metrics/AbcSize
    pattern = PlateTemplate.find(params[:id])
    pattern.update_params!(
      name: params[:name],
      user_id: current_user.id,
      wells: params[:empty_well],
      rows: params[:rows],
      cols: params[:cols]
    )
    flash[:notice] = 'Template updated'
    redirect_to plate_templates_path
  end

  def destroy
    pattern = PlateTemplate.find(params[:id])
    pattern.destroy

    respond_to { |format| format.html { redirect_to(plate_templates_path) } }
  end
end
