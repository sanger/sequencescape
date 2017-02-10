# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

class PlateTemplatesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :slf_manager_login_required

  def index
    @patterns = PlateTemplate.paginate(page: params[:page], per_page: 50)
  end

  def new
    @plate_rows = params[:rows].to_i
    @plate_cols = params[:cols].to_i
    if @plate_rows == 0
      @plate_rows = Map::Coordinate.plate_length(96)
    end
    if @plate_cols == 0
      @plate_cols = Map::Coordinate.plate_width(96)
    end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    if params[:name].blank?
      flash[:error] = 'Please enter a name'
      redirect_to new_plate_template_path
      return
    end

    pattern = PlateTemplate.new
    pattern.update_params!(name: params[:name], user_id: current_user.id, wells: params[:empty_well], control_well: params[:control_well], rows: params[:rows], cols: params[:cols])
    flash[:notice] = 'Template saved'
    redirect_to plate_templates_path
  end

  def edit
    @pattern = PlateTemplate.find(params[:id])
    @plate_rows = Map::Coordinate.plate_length(@pattern.size)
    @plate_cols = Map::Coordinate.plate_width(@pattern.size)
  end

  def update
    pattern = PlateTemplate.find(params[:id])
    pattern.update_params!(name: params[:name], user_id: current_user.id, control_well: params[:control_well], wells: params[:empty_well], rows: params[:rows], cols: params[:cols])
    flash[:notice] = 'Template updated'
    redirect_to plate_templates_path
  end

  def destroy
    pattern = PlateTemplate.find(params[:id])
    pattern.destroy

    respond_to do |format|
      format.html { redirect_to(plate_templates_path) }
    end
  end
end
