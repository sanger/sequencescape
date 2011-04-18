class ItemsController < ApplicationController

  def index
    @items = Item.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @items }
    end
  end

  def show
    @item = Item.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item }
      format.json { render :json => @item.to_json }
    end
  end

  def new
    @item = Item.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item }
    end
  end

  def edit
    @item = Item.find(params[:id])
  end

  def create
    @item = Item.new(params[:item])

    respond_to do |format|
      if @item.save
        flash[:notice] = 'Item was successfully created.'
        format.html { redirect_to(@item) }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @item = Item.find(params[:id])

    respond_to do |format|
      if @item.update_attributes(params[:item])
        flash[:notice] = 'Item was successfully updated.'
        format.html { redirect_to(@item) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.xml  { head :ok }
    end
  end

  def run_lanes
    render :text => "", :status => :gone
  end

  def asset_lookup_table
    @lookup_table = []
    @lookup_table << "Item_ID, Request_ID, Request_Type, Asset_ID, STI_type, Barcode\n"
    Request.all.each do |request|
      item_id = 0
      asset_id = 0
      request_id = 0
      barcode = ""
      sti_type = ""
      request_type = ""

      unless request.asset_id.nil?
        asset = Asset.find(request.asset_id)
        unless asset.nil?
          unless asset.barcode.nil?
            barcode = asset.barcode
          end
          unless asset.sti_type.nil?
            sti_type = asset.sti_type
          end
        end
      end

      unless request.item_id.nil?
        item_id = request.item_id
      end
      unless request.asset_id.nil?
        asset_id = request.asset_id
      end
      unless request.id.nil?
        request_id = request.id
      end

      unless request.request_type_id.nil?
        unless request.request_type_id == 4
          requesttype = RequestType.find(request.request_type_id)
          unless requesttype.nil?
            request_type = requesttype.name
          end
          row = "#{item_id}, #{request_id}, #{request_type}, #{asset_id}, #{sti_type}, #{barcode}\n"
          @lookup_table << row
        end
      end
    end
    render :text => @lookup_table
  end

end
