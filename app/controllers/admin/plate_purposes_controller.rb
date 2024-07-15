# frozen_string_literal: true
class Admin::PlatePurposesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource
  before_action :discover_plate_purpose, only: %i[show edit update destroy]

  def index
    plate_purposes = PlatePurpose.all
    @plate_purposes = plate_purposes.map { |purpose| purpose.becomes(PlatePurpose) }

    respond_to do |format|
      format.html
      format.xml { render xml: @plate_purposes }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @plate_purpose }
    end
  end

  def new
    @plate_purpose = PlatePurpose.new

    respond_to do |format|
      format.html
      format.xml { render xml: @plate_purpose }
    end
  end

  def edit
  end

  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @plate_purpose = PlatePurpose.new(params[:plate_purpose])

    respond_to do |format|
      if @plate_purpose.save
        flash[:notice] = 'Plate Purpose was successfully created.'
        format.html { redirect_to(admin_plate_purposes_path) }
        format.xml { render xml: @plate_purpose, status: :created, location: @plate_purpose }
      else
        format.html { render action: 'new' }
        format.xml { render xml: @plate_purpose.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @plate_purpose.update(params[:plate_purpose])
        flash[:notice] = 'Plate Purpose was successfully updated.'
        format.html { redirect_to(admin_plate_purposes_path) }
        format.xml { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @plate_purpose.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @plate_purpose.destroy

    respond_to do |format|
      format.html { redirect_to(admin_plate_purposes_url) }
      format.xml { head :ok }
    end
  end

  private

  def discover_plate_purpose
    @plate_purpose = PlatePurpose.find(params[:id])
  end
end
