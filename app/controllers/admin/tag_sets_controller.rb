# frozen_string_literal: true
##
# This class is the controller for Tag Sets which are used to link together two related tag groups.
# It allows you to create and view Tag Sets.
class Admin::TagSetsController < ApplicationController
  authorize_resource

  def index
    @tag_sets = TagSet.all

    respond_to { |format| format.html }
  end

  def show
    @tag_set = TagSet.find(params[:id])

    respond_to { |format| format.html }
  end

  def new
    @tag_set = TagSet.new

    respond_to { |format| format.html }
  end

  def create
    @tag_set = TagSet.new(tag_set_params)

    respond_to do |format|
      if @tag_set.save
        flash[:notice] = 'Tag Set was successfully created.'
        format.html { redirect_to admin_tag_set_path(@tag_set) }
      else
        format.html { render action: :new }
      end
    end
  end

  def tag_set_params
    params.require(:tag_set).permit(:name, :tag_group_id, :tag2_group_id)
  end
end
