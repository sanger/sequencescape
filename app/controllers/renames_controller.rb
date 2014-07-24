class RenamesController < ApplicationController

  before_filter :find_study, :only => [ :filter_change_name, :change_name ]

  def find_study
    @study  = Study.find(params[:id])
  end

  def filter_change_name
    @change_name = Rename::ChangeName.new(:study => @study, :user => @current_user)
    respond_to do |format|
      format.html
    end
  end

  def change_name
    @change_name = Rename::ChangeName.new({:study => @study, :user => @current_user}.merge(params[:change_name] || {})).execute!
    flash[:notice] = "Update. Below you find the new situation."
    redirect_to filter_change_name_rename_path(params[:id])
   rescue Rename::ChangeName::InvalidAction => exception
      flash[:error] = "Failed! Please, read the list of problem below."
      @change_name = exception.object
      render(:action => :filter_change_name)
  end
end