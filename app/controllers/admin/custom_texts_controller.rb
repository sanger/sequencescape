# frozen_string_literal: true
class Admin::CustomTextsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource

  def index
    @custom_texts = CustomText.all

    respond_to do |format|
      format.html
      format.xml { render xml: @custom_texts.to_xml }
    end
  end

  def show
    @custom_text = CustomText.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render xml: @custom_text.to_xml }
    end
  end

  def new
    @custom_text = CustomText.new
  end

  def edit
    @custom_text = CustomText.find(params[:id])
    respond_to { |format| format.html }
  end

  def create
    @custom_text = CustomText.new(params[:custom_text])
    respond_to do |format|
      if @custom_text.save
        flash[:notice] = 'Custom text successfully created'
        format.html { redirect_to admin_custom_text_path(@custom_text) }
      else
        flash[:error] = 'Problems creating your new custom text'
        format.html { render action: :new }
      end
    end
  end

  def update
    @custom_text = CustomText.find(params[:id])
    if @custom_text.update(params[:custom_text])
      flash[:notice] = 'Details have been updated'
      redirect_to admin_custom_text_path(@custom_text)
    else
      flash[:error] = 'Failed to update attributes'
      render action: 'edit', id: @custom_text.id
    end
  end

  def destroy
    custom_text = CustomText.find(params[:id])
    flash[:notice] = custom_text.destroy ? 'Custom text deleted' : 'Failed to destroy custom text'
    redirect_to admin_custom_texts_url
  end
end
