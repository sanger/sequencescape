class LocationsController < ApplicationController
  before_filter :find_location_by_id, :only => [:show, :edit, :update, :destroy]

  def index
    @locations = Location.find(:all)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @locations }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @location }
    end
  end

  def new
    @location = Location.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @location }
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
        format.xml  { render :xml => @location, :status => :created, :location => @location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
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
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
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
