# frozen_string_literal: true

##
# This class handles creating and viewing Tag Layout Templates, which describe how
# the Tags in a Tag Group are to be laid out in their labware container. For example
# that they should be laid out column by column across a plate.
# NB. Not all combinations will be valid.
class TagLayoutTemplatesController < ApplicationController
  authorize_resource

  def index
    @tag_layout_templates = TagLayoutTemplate.all

    respond_to { |format| format.html }
  end

  def show
    @tag_layout_template = TagLayoutTemplate.find(params[:id])

    respond_to { |format| format.html }
  end

  ##
  # Allows for the passing in of tag group id using a link from the tag group show page.
  def new
    @tag_layout_template = TagLayoutTemplate.new(tag_group_id: params[:tag_group_id])
    @direction_algorithms = TagLayout::DIRECTION_ALGORITHMS
    @walking_algorithms = TagLayout::WALKING_ALGORITHMS

    respond_to { |format| format.html }
  end

  def create
    @tag_layout_template = TagLayoutTemplate.new(tag_layout_template_params)

    respond_to do |format|
      if @tag_layout_template.save
        flash[:notice] = I18n.t('tag_groups.success')
        format.html { redirect_to(@tag_layout_template) }
      else
        @direction_algorithms = Taglayout::DIRECTION_ALGORITHMS
        @walking_algorithms = TagLayout::WALKING_ALGORITHMS
        format.html { render action: 'new' }
      end
    end
  end

  def tag_layout_template_params
    params.require(:tag_layout_template).permit(
      :name,
      :tag_group_id,
      :tag2_group_id,
      :direction_algorithm,
      :walking_algorithm
    )
  end
end
