# frozen_string_literal: true
# Add and edit {BaitLibrary::Supplier}s
class Admin::BaitLibraries::BaitLibrarySuppliersController < ApplicationController
  authorize_resource class: BaitLibrary::Supplier
  before_action :discover_bait_library_supplier, only: %i[edit update destroy]

  def new
    @bait_library_supplier = BaitLibrary::Supplier.new
  end

  def edit
  end

  def create
    @bait_library_supplier = BaitLibrary::Supplier.new(bait_library_supplier_params)

    respond_to do |format|
      if @bait_library_supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library_supplier.update(bait_library_supplier_params)
        flash[:notice] = 'Supplier was successfully updated.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    usage_count = @bait_library_supplier.bait_libraries.visible.count
    if usage_count > 0
      name = @bait_library_supplier.name
      flash[:error] = "Can not delete '#{name}', supplier is in use by #{usage_count} libraries."
    else
      @bait_library_supplier.hide
      flash[:notice] = 'Supplier was successfully deleted.'
    end

    redirect_to(admin_bait_libraries_path)
  end

  private

  def bait_library_supplier_params
    params.require(:bait_library_supplier).permit(:name)
  end

  def discover_bait_library_supplier
    @bait_library_supplier = BaitLibrary::Supplier.find(params[:id])
  end
end
