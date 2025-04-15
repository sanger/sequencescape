# frozen_string_literal: true
# rubocop:todo Metrics/ClassLength
class Studies::AssetGroupsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    @study = Study.find(params[:study_id])
    @asset_groups = @study.asset_groups

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @asset_groups }
    end
  end

  def show
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @asset_group }
    end
  end

  def new
    @asset_group = AssetGroup.new
    @study = Study.find(params[:study_id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @asset_group }
    end
  end

  def edit
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])
  end

  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @study = Study.find(params[:study_id])
    @asset_group = AssetGroup.new(params[:asset_group])
    @asset_group.study = @study

    respond_to do |format|
      if @asset_group.save
        flash[:notice] = 'AssetGroup was successfully created.'
        format.html { redirect_to study_asset_group_path(@study, @asset_group) }
        format.xml { render xml: @asset_group, status: :created, location: @asset_group }
        format.json { render json: @asset_group, status: :created, location: @asset_group }
      else
        format.html { render action: 'new' }
        format.xml { render xml: @asset_group.errors, status: :unprocessable_entity }
        format.json { render json: @asset_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])

    respond_to do |format|
      if @asset_group.update(params[:asset_group])
        flash[:notice] = 'AssetGroup was successfully updated.'
        format.html { redirect_to study_asset_group_path(@study, @asset_group) }
        format.xml { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @asset_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @asset_group = AssetGroup.find(params[:id])
    @asset_group.destroy
    @study = Study.find(params[:study_id])

    respond_to do |format|
      format.html { redirect_to(study_asset_groups_url(@study)) }
      format.xml { head :ok }
    end
  end

  # rubocop:todo Metrics/MethodLength
  def search # rubocop:todo Metrics/AbcSize
    @study = Study.find(params[:study_id])
    query = params[:q]
    if query.blank? || (query.length < 2)
      # We should not blame the user, we should instead help.
      # - By returning the X most recent ones together with an explanation.
      flash[:error] = 'Search too wide. Please make your query more specific.'
      redirect_to study_asset_groups_path(@study)
      return
    else
      @assets = Labware.where(['name like ?', "%#{query}%"])
    end
    @asset_group = AssetGroup.find(params[:id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @assets }
    end
  end

  # rubocop:enable Metrics/MethodLength

  def add # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])
    if params[:asset]
      ids = params[:asset].select { |_asset_id, checked| checked == '1' }.keys
      @assets = Labware.find(ids)
      @assets.each do |asset|
        @asset_group.assets << asset.receptacles
      end
    end

    respond_to do |format|
      format.html { redirect_to(study_asset_group_url(@study, @asset_group)) }
      format.xml { render xml: @assets }
      format.json { render json: @assets }
    end
  end

  def printing
    @study = Study.find(params[:study_id])
    @asset_groups = @study.asset_groups
  end

  def print
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])

    @labware = @asset_group.labware.select { |asset| asset.is_a?(Barcode::Barcodeable) }
  end

  def print_labels # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @asset_group = AssetGroup.find(params[:id])
    @study = Study.find(params[:study_id])

    print_job =
      LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::AssetRedirect, printables: params[:printables])
    if print_job.execute
      flash[:notice] = print_job.success
      redirect_to study_asset_groups_path(@study)
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
      redirect_to print_study_asset_group_path(@study, @asset_group)
    end
  end
end
# rubocop:enable Metrics/ClassLength
