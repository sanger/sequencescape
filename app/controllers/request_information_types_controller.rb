class RequestInformationTypesController < ApplicationController
  before_filter :find_request_information_type_by_id, :only => [:show, :edit, :update, :destroy]

  def index
    @request_information_types = RequestInformationType.find(:all)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @request_information_types }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @request_information_type }
    end
  end

  def new
    @request_information_type = RequestInformationType.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @request_information_type }
    end
  end

  def edit
  end

  def create
    @request_information_type = RequestInformationType.new(params[:request_information_type])

    respond_to do |format|
      if @request_information_type.save
        flash[:notice] = 'RequestInformationType was successfully created.'
        format.html { redirect_to(@request_information_type) }
        format.xml  { render :xml => @request_information_type, :status => :created, :location => @request_information_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @request_information_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @request_information_type.update_attributes(params[:request_information_type])
        flash[:notice] = 'RequestInformationType was successfully updated.'
        format.html { redirect_to(@request_information_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @request_information_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @request_information_type.destroy

    respond_to do |format|
      format.html { redirect_to(request_information_types_url) }
      format.xml  { head :ok }
    end
  end

  def find_request_information_type_by_id
    @request_information_type = RequestInformationType.find(params[:id])
  end
end
