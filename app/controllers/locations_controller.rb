# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class LocationsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_location_by_id, only: [:show, :edit, :update, :destroy]

  def index
    @locations = Location.all

    respond_to do |format|
      format.html
      format.xml { render xml: @locations }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @location }
    end
  end

  def new
    @location = Location.new

    respond_to do |format|
      format.html
      format.xml { render xml: @location }
    end
  end

  def edit
  end

  def create
    @location = Location.new(params[:location])

    respond_to do |format|
      if @location.save
        flash[:notice] = 'Location was successfully created.'
        format.html { redirect_to(@location) }
        format.xml  { render xml: @location, status: :created, location: @location }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @location.update_attributes(params[:location])
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_to(@location) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @location.destroy

    respond_to do |format|
      format.html { redirect_to(locations_url) }
      format.xml  { head :ok }
    end
  end

  def find_location_by_id
    @location = Location.find(params[:id])
  end
end
