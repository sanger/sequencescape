class Studies::DocumentsController < ApplicationController
  before_filter :get_study_id

  def index
    @study = Study.find(params[:study_id])
    @documents = @study.documents
  end


  def new
    @study = Study.find(params[:study_id])
  end

  def create
    document_settings = params[:document]
    document_settings[:documentable_id] = @study.id

    @document = Document.new(document_settings)
    begin
      if @document.save
        flash[:notice] = "Document was saved okay"
        redirect_to url_for(:controller => "admin/studies", :action => "show", :id => @study.id)
      else
        render :action => "new"
      end
    rescue ActiveRecord::StatementInvalid
      flash[:error] = "Something bad happened. Perhaps karma has caught up with you?"
      redirect_to url_for(:controller => "admin/studies", :action => "show", :id => @study.id)
    end
  end

  def show
    @document = Document.find(params[:id])
    send_data @document.current_data, :filename => @document.filename, :type => @document.content_type, :disposition => 'inline'
  end

  def destroy
    @document = Document.find(params[:id])
    if @document.destroy
      flash[:notice] = "Document was successfully deleted"
      redirect_to url_for(:controller => "admin/studies", :action => "show", :id => @study.id)
    else
      flash[:error] = "Document cannot be destroyed"
      redirect_to url_for(:controller => "admin/studies", :action => "show", :id => @study.id)
    end
  end

  private

  def get_study_id
    @study = Study.find(params[:study_id])
  end
end
