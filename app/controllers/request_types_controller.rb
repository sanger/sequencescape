class RequestTypesController < ApplicationController

  before_filter :admin_login_required

  # GET /request_types
  # GET /request_types.xml
  def index
    @request_types = RequestType.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @request_types }
    end
  end

  # GET /request_types/1
  # GET /request_types/1.xml
  def show
    @request_type = RequestType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @request_type }
    end
  end

  # GET /request_types/new
  # GET /request_types/new.xml
  def new
    @request_type = RequestType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @request_type }
    end
  end

  # GET /request_types/1/edit
  def edit
    @request_type = RequestType.find(params[:id])
  end

  # POST /request_types
  # POST /request_types.xml
  def create
    @request_type = RequestType.new(params[:request_type])

    respond_to do |format|
      if @request_type.save
        flash[:notice] = 'RequestType was successfully created.'
        format.html { redirect_to(@request_type) }
        format.xml  { render :xml => @request_type, :status => :created, :location => @request_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @request_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /request_types/1
  # PUT /request_types/1.xml
  def update
    @request_type = RequestType.find(params[:id])

    respond_to do |format|
      if @request_type.update_attributes(params[:request_type])
        flash[:notice] = 'RequestType was successfully updated.'
        format.html { redirect_to(@request_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @request_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /request_types/1
  # DELETE /request_types/1.xml
  def destroy
    @request_type = RequestType.find(params[:id])
    @request_type.destroy

    respond_to do |format|
      format.html { redirect_to(request_types_url) }
      format.xml  { head :ok }
    end
  end
end
