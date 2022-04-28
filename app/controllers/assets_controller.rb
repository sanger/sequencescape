# frozen_string_literal: true
# {Labware} and {Receptacle} used to both be grouped under {Asset} and this
# controller handled them. Now the majority of the behaviour has moved off into
# the respective controllers. This remains to handle a few legacy endpoints:
#
# show: Kept in place for CGP who were supposed to migrate off, but as of 23/12/2020
#       I'm (JG) still seeing activity. It might be we have another user who hasn't
#       migrated. Currently it just mimics the receptacle show behaviour for xml requests.
#       We also have a disambiguation page to handle links in from NPG, until they update
#       to use the receptacles endpoint. Again, we're still getting activity here, so
#       it looks like that hasn't happened yet.
# print_labels: This is used by the PhiX tubes created in the  PhiX::SpikedBuffersController
#               and PhiX::StocksController. It doesn't belong here.
# lookup: I can't find any links to this page, and it doesn't appear to have been used recently.
#         However our logs don't go back all that far. Provides a page for scanning in barcodes.
#         It appears to be supposed to redirect to the labware page, but it blows up for tubes
#         and shows the qc information for plates.
class AssetsController < ApplicationController
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/AbcSize
  def show # rubocop:todo Metrics/CyclomaticComplexity
    # LEGACY API FOR CGP to allow switch-over
    # In future they will use the recpetacles/:id/parent
    if request.format.xml?
      @asset = Receptacle.include_for_show.find(params[:id])
      respond_to { |format| format.xml }
      return
    end

    # Disambiguation page for legacy NPG links
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

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

  # TODO: This is currently used from the PhiX::SpikedBuffersController and
  # PhiX::StocksController show pages. It doesn't really belong here.
  def print_labels
    print_job =
      LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::AssetRedirect, printables: params[:printables])
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to phi_x_url
  end

  # JG 23/12/2020: I can't find any links to this page, and think we can probably lose it.
  def lookup # rubocop:todo Metrics/AbcSize
    if params[:asset] && params[:asset][:barcode]
      @assets = Labware.with_barcode(params[:asset][:barcode]).limit(50).page(params[:page])

      case @assets.size
      when 1
        redirect_to @assets.first
      when 0
        flash.now[:error] = "No asset found with barcode #{params[:asset][:barcode]}"
        respond_to do |format|
          format.html { render action: 'lookup' }
          format.xml { render xml: @assets.to_xml }
        end
      else
        respond_to do |format|
          format.html { render action: 'index' }
          format.xml { render xml: @assets.to_xml }
        end
      end
    end
  end
end
