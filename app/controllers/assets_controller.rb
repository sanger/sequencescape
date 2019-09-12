class AssetsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_asset, only: %i[edit update summary print_assets print history]
  before_action :prepare_asset, only: %i[new_request create_request]

  def index
    if params[:study_id]
      redirect_to study_information_receptacles_path(params[:study_id])
      return
    else
      @assets = Asset.page(params[:page])
    end

    respond_to do |format|
      format.html
      if params[:sample_id]
        format.xml { render xml: Sample.find(params[:sample_id]).assets.to_xml }
      elsif params[:asset_id]
        @asset = Asset.find(params[:asset_id])
        format.xml { render xml: ['relations' => { 'parents' => @asset.parents, 'children' => @asset.children }].to_xml }
      end
    end
  end

  def show
    # LEGACY API FOR CGP to allow switch-over
    # In future they will use the recpetacles/:id/parent
    if request.format.xml?

      @asset = Receptacle.include_for_show.find(params[:id])
      respond_to { |format| format.xml }
      return
    end

    @labware = Labware.find_by(id: params[:id])
    @receptacle = Receptacle.find_by(id: params[:id])

    if @receptacle.nil? && @labware.nil?
      raise ActiveRecord::RecordNotFound
    elsif @labware.nil? || @labware.try(:receptacle) == (@receptacle || :none)
      redirect_to receptacle_path(@receptacle)
    elsif @receptacle.nil? && @labware.present?
      redirect_to labware_path(@labware)
    else
      # Things are ambiguous, we'll make you select
      render :show, status: :multiple_choices
    end
  end

  def edit
    @valid_purposes_options = @asset.compatible_purposes.pluck(:name, :id)
  end

  def history
    respond_to do |format|
      format.html
      format.xml  { @request.events.to_xml }
      format.json { @request.events.to_json }
    end
  end

  def update
    respond_to do |format|
      if @asset.update(asset_params.merge(params.to_unsafe_h.fetch(:lane, {})))
        flash[:notice] = 'Asset was successfully updated.'
        if params[:lab_view]
          format.html { redirect_to(action: :lab_view, barcode: @asset.human_barcode) }
        else
          format.html { redirect_to(action: :show, id: @asset.id) }
          format.xml  { head :ok }
        end
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @asset.errors, status: :unprocessable_entity }
      end
    end
  end

  private def asset_params
    permitted = %i[volume concentration]
    permitted << :name if current_user.administrator?
    permitted << :plate_purpose_id if current_user.administrator? || current_user.lab_manager?
    params.require(:asset).permit(permitted)
  end

  def summary
    @summary = UiHelper::Summary.new(per_page: 25, page: params[:page])
    @summary.load_asset(@asset)
  end

  def print
    if @asset.printable?
      @printable = @asset.printable_target
      @direct_printing = (@asset.printable_target == @asset)
    else
      flash[:error] = "#{@asset.display_name} does not have a barcode so a label can not be printed."
      redirect_to asset_path(@asset)
    end
  end

  def print_labels
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                           LabelPrinter::Label::AssetRedirect,
                                           printables: params[:printables])
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to phi_x_url
  end

  def print_assets
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                           LabelPrinter::Label::AssetRedirect,
                                           printables: @asset)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
    redirect_to asset_url(@asset)
  end

  def show_plate
    @asset = Plate.find(params[:id])
  end

  def lookup
    if params[:asset] && params[:asset][:barcode]
      @assets = Labware.with_barcode(params[:asset][:barcode]).limit(50).page(params[:page])

      if @assets.size == 1
        redirect_to @assets.first
      elsif @assets.size == 0
        flash.now[:error] = "No asset found with barcode #{params[:asset][:barcode]}"
        respond_to do |format|
          format.html { render action: 'lookup' }
          format.xml  { render xml: @assets.to_xml }
        end
      else
        respond_to do |format|
          format.html { render action: 'index' }
          format.xml  { render xml: @assets.to_xml }
        end
      end
    end
  end

  private

  # Receptacle, as we're about to request some stuff
  def prepare_asset
    @asset = Receptacle.find(params[:id])
  end

  def new_request_for_current_asset
    new_request_asset_path(@asset, study_id: @study.try(:id), project_id: @project.try(:id), request_type_id: @request_type.try(:id))
  end

  def discover_asset
    @asset = Asset.include_for_show.find(params[:id])
  end
end
