class Admin::BaitLibraries::BaitLibrarySuppliersController < ApplicationController
  before_filter :admin_login_required
  before_filter :discover_bait_library_supplier, :only => [:edit, :update, :destroy]
  def new
    @bait_library_supplier = BaitLibrary::Supplier.new
  end

  def edit
  end

  def create
    @bait_library_supplier = BaitLibrary::Supplier.new(params[:bait_library_supplier])

    respond_to do |format|
      if @bait_library_supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library_supplier.update_attributes(params[:bait_library_supplier])
        flash[:notice] = 'Supplier was successfully updated.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    bait_libraries = BaitLibrary.find(
      :all,
      :conditions => ["visible = ? AND bait_library_supplier_id =?", true, @bait_library_supplier.id]
    )
    if bait_libraries.length > 0
      respond_to do |format|
        flash[:error] = "Can not delete '#{@bait_library_supplier.name}', supplier is in use.<br/>
        Supplier for: #{bait_libraries.map(&:name).join(', ')}."
        format.html { redirect_to(bait_libraries_path) }
      end
    else
      @bait_library_supplier.update_attributes(:visible => false)
      respond_to do |format|
        flash[:notice] = 'Supplier was successfully deleted.'
        format.html { redirect_to(bait_libraries_path) }
      end
    end
  end
  private
  def discover_bait_library_supplier
    @bait_library_supplier = BaitLibrary::Supplier.find(params[:id])
  end
end