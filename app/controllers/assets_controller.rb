#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.


class AssetsController < ApplicationController
  include BarcodePrintersController::Print
   before_filter :discover_asset, :only => [:show, :edit, :update, :destory, :summary, :close, :print_assets, :print, :show_plate, :history, :holded_assets]

  def index
    @assets_without_requests = []
    @assets_with_requests = []
    if params[:study_id]
      @study = Study.find(params[:study_id])
      @assets = @study.assets_through_aliquots.order('name ASC').paginate(:page => params[:page])
    end

    respond_to do |format|
      if params[:print]
        format.html { render :action => :print_index }
      else
        format.html
      end
      if params[:study_id]
        format.xml  { render :xml => Study.find(params[:study_id]).assets_through_requests.to_xml }
      elsif params[:sample_id]
          format.xml  { render :xml => Sample.find(params[:sample_id]).assets.to_xml }
      elsif params[:asset_id]
        @asset = Asset.find(params[:asset_id])
        format.xml  { render :xml => ["relations" => {"parents" => @asset.parents, "children" => @asset.children}].to_xml }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.json { render :json => @asset }
    end
  end

  def new
    @asset = Asset.new
    @asset_types = { "Library Tube" => 'LibraryTube', "Hybridization Buffer Spiked" => "SpikedBuffer" }
    @phix_tag = TagGroup.find_by_name(configatron.phix_tag.tag_group_name).tags.select do |t|
      t.map_id == configatron.phix_tag.tag_map_id
    end.first

    respond_to do |format|
      format.html
      format.xml  { render :xml => @asset }
    end
  end

  def edit
    @valid_purposes_options = @asset.compatible_purposes.map do |purpose|
      [purpose.name, purpose.id]
    end
  end

  def find_parents(text)
    return [] unless text.present?
      names = text.lines.map(&:chomp).reject { |l| l.blank? }
      objects = Asset.find(:all, :conditions => {:id => names})
      objects += Asset.find(:all, :conditions => {:barcode => names})
      name_set = Set.new(names)
      found_set = Set.new(objects.map(&:name))
      not_found = name_set - found_set
      raise InvalidInputException, "#{Asset.table_name} #{not_found.to_a.join(", ")} not founds" unless not_found.empty?
      return objects
  end

  def create

    count = first_param(:count)
    count = count.present? ? count.to_i : 1
    saved = true

    begin
      # Find the parent asset up front
      parent, parent_param = nil, first_param(:parent_asset)
      if parent_param.present?
        parent = Asset.find_from_machine_barcode(parent_param) || Asset.find_by_name(parent_param) || Asset.find_by_id(parent_param)
        raise StandardError, "Cannot find the parent asset #{parent_param.inspect}" if parent.nil?
      end

      # Find the tag up front
      tag, tag_param = nil, first_param(:tag)
      if tag_param.present?
        conditions = { :map_id => tag_param }
        oligo      = params[:tag_sequence]
        conditions[:oligo] = oligo.first.upcase if oligo.present? and oligo.first.present?
        tag = Tag.first(:conditions => conditions) or raise StandardError, "Cannot find tag #{tag_param.inspect}"
      end

      sti_type    = params[:asset].delete(:sti_type) or raise StandardError, "No asset type specified"
      asset_class = sti_type.constantize

      ActiveRecord::Base.transaction do
        @assets = (1..count).map do |n|
          asset = asset_class.new(params[:asset]) do |asset|
            asset.name += " ##{n}" if count !=1
          end
          # from asset
          if parent.present?
            parent_volume, parent_used = params[:parent_volume], parent
            if parent_volume.present? and parent_volume.first.present?

              extract = parent_used.transfer(parent_volume.first)

              if asset.volume
                parent_used = extract
                asset.save!
              elsif asset.is_a?(SpikedBuffer) and !parent_used.is_a?(SpikedBuffer)
                raise StandardError, "Enter a volume"
              else
                # Discard the 'asset' that was build initially as it is being replaced by the asset
                # created from the extraction process.
                extract.update_attributes!(:name => asset.name)
                asset, parent_used = extract, nil
              end
            end
            # We must copy the aliquots of the 'extract' to the asset, otherwise the asset remains empty.
            asset.aliquots = parent_used.aliquots.map(&:dup) unless parent_used.nil?
            asset.add_parent(parent_used)
          else
            # All new assets are assumed to have a phiX sample in them as that's the only asset that
            # is created this way.
            asset.save!
            aliquot_attributes = { :sample => SpikedBuffer.phiX_sample, :study_id => 198 }
            aliquot_attributes[:library] = asset if asset.is_a?(LibraryTube) or asset.is_a?(SpikedBuffer)
            asset.aliquots.create!(aliquot_attributes)
          end
          tag.tag!(asset) if tag.present?
          asset.update_attributes!(:barcode => AssetBarcode.new_barcode) if asset.barcode.nil?
          asset.comments.create!(:user => current_user, :description => "asset has been created by #{current_user.login}")
          asset
        end
      end # transaction
    rescue Asset::VolumeError => ex
      saved = false
      flash[:error] = ex.message
    rescue => exception
      saved = false
      flash[:error] = exception.message
    end

    respond_to do |format|
      if saved
        flash[:notice] = 'Asset was successfully created.'
        format.html { render :action => :create}
        format.xml  { render :xml => @assets, :status => :created, :location => assets_url(@assets) }
        format.json { render :json => @assets, :status => :created, :location => assets_url(@assets) }
      else
        format.html { redirect_to :action => "new" }
        format.xml  { render :xml => @assets.errors, :status => :unprocessable_entity }
        format.json { render :json => @assets.errors, :status => :unprocessable_entity }
      end
    end
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
      if (@asset.update_attributes(params[:asset]) &&  @asset.update_attributes(params[:lane]))
        flash[:notice] = 'Asset was successfully updated.'
        unless params[:lab_view]
          format.html { redirect_to(:action => :show, :id => @asset.id) }
          format.xml  { head :ok }
        else
          format.html { redirect_to(:action => :lab_view, :barcode => @asset.barcode) }
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @asset.destroy

    respond_to do |format|
      format.html { redirect_to(assets_url) }
      format.xml  { head :ok }
    end
  end

  def summary
    @summary = UiHelper::Summary.new({:per_page => 25, :page => params[:page]})
    @summary.load_item(@asset)
  end

  def close
    @asset.closed = !@asset.closed
    @asset.save
    respond_to do |format|
      if  @asset.closed
        flash[:notice] = "Asset #{@asset.name} was closed."
      else
        flash[:notice] = "Asset #{@asset.name} was opened."
      end
      format.html { redirect_to(asset_url(@asset)) }
      format.xml  { head :ok }
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
    print_asset_labels(new_asset_url, new_asset_url)
  end

  def print_assets
    params[:printables]={@asset =>1}
    return print_asset_labels(asset_url(@asset), asset_url(@asset))
  end

  def show_plate
  end

  before_filter :prepare_asset, :only => [ :new_request, :create_request ]

  def prepare_asset
    @asset = Asset.find(params[:id])
  end
  private :prepare_asset

  def new_request_for_current_asset
    new_request_asset_path(@asset, {:study_id => @study.try(:id), :project_id => @project.try(:id), :request_type_id => @request_type.id})
  end
  private :new_request_for_current_asset

  def new_request
    @request_types = RequestType.applicable_for_asset(@asset)
    @study = @asset.studies.first
    @project = @asset.projects.first || @asset.studies.first && @asset.studies.first.projects.first
  end

  def create_request
    @request_type = RequestType.find(params[:request_type_id])
    @study        = Study.find(params[:study_id]) unless params[:cross_study_request].present?
    @project      = Project.find(params[:project_id]) unless params[:cross_project_request].present?

    request_options = params.fetch(:request, {}).fetch(:request_metadata_attributes, {})
    request_options[:multiplier] = { @request_type.id => params[:count].to_i } unless params[:count].blank?
    submission = ReRequestSubmission.build!(
      :study           => @study,
      :project         => @project,
      :workflow        => @request_type.workflow,
      :user            => current_user,
      :assets          => [ @asset ],
      :request_types   => [ @request_type.id ],
      :request_options => request_options,
      :comments        => params[:comments],
      :priority        => params[:priority]
    )

    respond_to do |format|
      flash[:notice] = 'Created request'

      format.html { redirect_to new_request_for_current_asset }
      format.json { render :json => submission.requests, :status => :created }
    end
  rescue Submission::ProjectValidation::Error => exception
    respond_to do |format|
      flash[:error] = exception.message
      format.html { redirect_to new_request_for_current_asset }
      format.json { render :json => exception.message, :status => :unprocessable_entity }
    end
  rescue ActiveRecord::RecordNotFound => exception
    respond_to do |format|
      flash[:error] = exception.message
      format.html { redirect_to new_request_for_current_asset }
      format.json { render :json => exception.message, :status => :precondition_failed }
    end
  rescue ActiveRecord::RecordInvalid => exception
    respond_to do |format|
      flash[:error] = exception.message
      format.html { redirect_to new_request_for_current_asset }
      format.json { render :json => exception.message, :status => :precondition_failed }
    end
  end

  def get_barcode
    barcode = Asset.get_barcode_from_params(params)
    render(:text => "#{Barcode.barcode_to_human(barcode)} => #{barcode}")
  end

  def get_barcode_from_params(params)
    prefix, asset = 'NT', nil
    if params[:prefix]
      prefix = params[:prefix]
    else
      begin
        asset = Asset.find(params[:id])
      rescue
      end
    end

    if asset and asset.barcode
      Barcode.calculate_barcode(asset.prefix, asset.barcode.to_i)
    else
      Barcode.calculate_barcode(prefix, params[:id].to_i)
    end
  end
  private :get_barcode_from_params

  def lookup
    if params[:asset] && params[:asset][:barcode]
      id = params[:asset][:barcode][3,7]
      @assets = Asset.find(:all, :conditions => {:barcode => id}).paginate :per_page => 50, :page => params[:page]

      if @assets.size == 1
        redirect_to @assets.first
      elsif @assets.size == 0
        flash.now[:error] = "No asset found with barcode #{params[:asset][:barcode]}"
        respond_to do |format|
          format.html { render :action => "lookup" }
          format.xml  { render :xml => @assets.to_xml }
        end
      else
        respond_to do |format|
          format.html { render :action => "index" }
          format.xml  { render :xml => @assets.to_xml }
        end
      end
    end
  end

  def reset_values_for_move
    render :layout => false
  end

  def find_by_barcode
  end

  def lab_view
    barcode = params[:barcode]
    if barcode.blank?
      redirect_to :action => "find_by_barcode"
    else
      if barcode.size == 13 && Barcode.check_EAN(barcode)
        num_prefix, number, _ = Barcode.split_barcode(barcode)
        prefix = BarcodePrefix.find_by_prefix(Barcode.prefix_to_human(num_prefix))
        @asset = Asset.find_by_barcode_and_barcode_prefix_id(number,prefix.id)
      else
        @asset = Asset.find_by_barcode(barcode)
      end

      if @asset.nil?
        flash[:error] = "Unable to find anything with this barcode"
        redirect_to :action => "find_by_barcode"
      end
    end
  end

  def create_stocks
    params[:assets].each do |id, params|
      asset = Asset.find(id)
      stock_asset = asset.create_stock_asset!(
        :name          => params[:name],
        :volume        => params[:volume],
        :concentration => params[:concentration]
      )
      stock_asset.assign_relationships(asset.parents, asset)
    end

    batch = Batch.find(params[:batch_id])
    redirect_to batch_path(batch)
  end

  private
  def discover_asset
    @asset = Asset.find(params[:id], :include => { :requests => :request_metadata })
  end

  def check_valid_values(params = nil)
    if (params[:study_id_to] == "0") || (params[:study_id_from] == "0")
      flash[:error] = "You have to select 'Study From' and 'Study To'"
      return false
    else
      study_from = Study.find(params[:study_id_from])
      study_to = Study.find(params[:study_id_to])
      if study_to.name.eql?(study_from.name)
        flash[:error] = "You can't select the same Study."
        return false
      elsif params[:asset_group_id] == "0" && params[:new_assets_name].empty?
        flash[:error] = "You must indicate an 'Asset Group'."
        return false
      elsif !(params[:asset_group_id] == "0") && !(params[:new_assets_name].empty?)
        flash[:error] = "You can select only an Asset Group!"
        return false
      elsif AssetGroup.find_by_name(params[:new_assets_name])
        flash[:error] = "The name of Asset Group exists!"
        return false
      end
    end
    return true
  end

end
