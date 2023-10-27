# frozen_string_literal: true
class Admin::BaitLibrariesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_bait_library, only: %i[edit update destroy]

  authorize_resource

  def index
    @bait_libraries = BaitLibrary.visible
    @bait_library_types = BaitLibraryType.visible
    @bait_library_suppliers = BaitLibrary::Supplier.visible
  end

  def new
    @bait_library = BaitLibrary.new
  end

  def edit; end

  def create
    @bait_library = BaitLibrary.new(params[:bait_library])

    respond_to do |format|
      if @bait_library.save
        flash[:notice] = 'Bait Library was successfully created.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library.update(params[:bait_library])
        flash[:notice] = 'Bait Library was successfully updated.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    respond_to do |format|
      flash[:notice] = 'Bait Library was successfully deleted.' if @bait_library.hide
      format.html { redirect_to(admin_bait_libraries_path) }
    end
  end

  private

  def discover_bait_library
    @bait_library = BaitLibrary.find(params[:id])
  end
end
