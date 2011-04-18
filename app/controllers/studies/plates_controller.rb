class Studies::PlatesController < ApplicationController
  before_filter :login_required, :discover_study
  # GET /plates
  # GET /plates.xml
  def index
    @plates = Plate.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @plates }
    end
  end

  # GET /plates/1
  # GET /plates/1.xml
  def show
    @plate = Plate.find(params[:id])
    @wells = @plate.wells.paginate :page => params[:page], :order => 'created_at DESC'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @plate }
    end
  end

  # filters wells based on previous selection
  def view_wells
    plate_ids = params[:plates].keys
    @wells    = []
    @plates   = Plate.find(plate_ids)

    respond_to do |format|
      format.html
      format.xml
    end
  end

  # add wells to asset group
  def asset_group
    @asset_group = AssetGroup.new(:name => params["asset_group_name"], :study => @study)

    Well.find(params[:wells].keys).each do |well|
      @asset_group.assets << well
    end

    if @asset_group.save
      respond_to do |format|
        flash[:notice] = "Wells successfully added to asset group #{@asset_group.name}."
        format.html { redirect_to(study_asset_groups_path(@study))}
        format.xml { head :ok }
      end
    end
  end

  private
  def discover_study
    @study = Study.find(params[:study_id])
  end
end
