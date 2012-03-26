class Admin::BaitLibrariesController < ApplicationController
  before_filter :admin_login_required
  before_filter :discover_bait_library, :only => [:edit, :update, :destroy]

  def index
    @bait_libraries = BaitLibrary.all
    @bait_library_types = BaitLibraryType.all
    @bait_library_suppliers = BaitLibrary::Supplier.all
  end

  def new
    @bait_library = BaitLibrary.new
  end

  def edit
  end

  def create
    @bait_library = BaitLibrary.new(params[:bait_library])

    respond_to do |format|
      if @bait_library.save
        flash[:notice] = 'Bait Library was successfully created.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library.update_attributes(params[:bait_library])
        flash[:notice] = 'Bait Library was successfully updated.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @bait_library.destroy
    respond_to do |format|
      flash[:notice] = 'Bait Library was successfully deleted.'
      format.html { redirect_to(bait_libraries_path) }
    end
  end

  private
  def discover_bait_library
    @bait_library = BaitLibrary.find(params[:id])
  end

end

class Admin::BaitLibraries::BaitLibraryTypesController < ApplicationController
  before_filter :admin_login_required
  before_filter :discover_bait_library_type, :only => [:edit, :update, :destroy]
  def new
    @bait_library_type = BaitLibraryType.new
  end

  def edit
  end

  def create
    @bait_library_type = BaitLibraryType.new(params[:bait_library_type])

    respond_to do |format|
      if @bait_library_type.save
        flash[:notice] = 'Bait Library Type was successfully created.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library_type.update_attributes(params[:bait_library_type])
        flash[:notice] = 'Bait Library Type was successfully updated.'
        format.html { redirect_to(bait_libraries_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @bait_library_type.destroy
    respond_to do |format|
      flash[:notice] = 'Bait Library Type was successfully deleted.'
      format.html { redirect_to(bait_libraries_path) }
    end
  end
  private
  def discover_bait_library_type
    @bait_library_type = BaitLibraryType.find(params[:id])
  end
end

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
    @bait_library_supplier.destroy
    respond_to do |format|
      flash[:notice] = 'Supplier was successfully deleted.'
      format.html { redirect_to(bait_libraries_path) }
    end
  end
  private
  def discover_bait_library_supplier
    @bait_library_supplier = BaitLibrary::Supplier.find(params[:id])
  end
end