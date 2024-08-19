# frozen_string_literal: true
##
# This class is the controller for Tag Sets which are used to link together two related tag groups.
# It allows you to create and view Tag Sets.
class TagSetsController < ApplicationController
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

  def create # rubocop:todo Metrics/MethodLength
    @tag_set = TagSet.new(tag_set_params)

    respond_to do |format|
      if @tag_set.save
        flash[:notice] = 'Tag Set successfully created'
        format.html { redirect_to tag_set_path(@tag_set) }
        format.xml { render xml: @tag_set, status: :created, location: @tag_set }
        format.json { render json: @tag_set, status: :created, location: @tag_set }
      else
        flash[:error] = 'Problems creating your new Tag Set'
        format.html { render action: :new }
        format.xml { render xml: @tag_set.errors, status: :unprocessable_entity }
        format.json { render json: @tag_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def tag_set_params
    params.require(:tag_set).permit(:name, :tag_group_id, :tag2_group_id)
  end
end
