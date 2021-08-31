class Admin::BaitLibraries::BaitLibraryTypesController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource
  before_action :discover_bait_library_type, only: %i[edit update destroy]
  def new
    @bait_library_type = BaitLibraryType.new
  end

  def edit; end

  def create
    @bait_library_type = BaitLibraryType.new(params[:bait_library_type])

    respond_to do |format|
      if @bait_library_type.save
        flash[:notice] = 'Bait Library Type was successfully created.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @bait_library_type.update(params[:bait_library_type])
        flash[:notice] = 'Bait Library Type was successfully updated.'
        format.html { redirect_to(admin_bait_libraries_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/MethodLength
  def destroy
    if @bait_library_type.bait_libraries.visible.count > 0
      respond_to do |format|
        flash[:error] =
          # rubocop:todo Layout/LineLength
          "Can not delete '#{@bait_library_type.name}', bait library type is in use by #{@bait_library_type.bait_libraries.visible.count} libraries."

        # rubocop:enable Layout/LineLength
        format.html { redirect_to(admin_bait_libraries_path) }
      end
    else
      respond_to do |format|
        flash[:notice] = 'Bait Library Type was successfully deleted.' if @bait_library_type.hide
        format.html { redirect_to(admin_bait_libraries_path) }
      end
    end
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def discover_bait_library_type
    @bait_library_type = BaitLibraryType.find(params[:id])
  end
end
