class AssetsController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :prepare_asset, only: %i[new_request create_request]

  def index
    if params[:study_id]
      redirect_to study_information_receptacles_path(params[:study_id])
    else
      redirect_to labware_index
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

  def show_plate
    @asset = Plate.find(params[:id])
  end

  def lookup
    if params[:asset] && params[:asset][:barcode]
      @assets = Labware.with_barcode(params[:asset][:barcode]).limit(50).page(params[:page])

      case @assets.size
      when 1
        redirect_to @assets.first
      when 0
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
end
