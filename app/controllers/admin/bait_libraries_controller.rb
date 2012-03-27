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