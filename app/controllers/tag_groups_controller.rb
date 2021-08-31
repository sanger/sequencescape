# frozen_string_literal: true
##
# This class is the controller for Tag Groups, which are basically used to record the grouping
# of a set of Sequencing Tags. It allows you to create and view Tag Groups.
class TagGroupsController < ApplicationController
  authorize_resource

  def index
    @tag_groups = TagGroup.includes(:adapter_type)

    respond_to { |format| format.html }
  end

  def show
    @tag_group = TagGroup.find(params[:id])

    respond_to { |format| format.html }
  end

  ##
  # The new method uses a form object to handle the naming of the Tag Group and the input
  # and validation of the Tag oligo sequences.
  def new
    @form_object = TagGroup::FormObject.new

    respond_to { |format| format.html }
  end

  ##
  # The create method uses a form object to validate the user input of the oligo sequences
  # and handle the creation of Tags within a new Tag Group.
  def create
    @form_object = TagGroup::FormObject.new(tag_group_form_object_params)

    respond_to do |format|
      if @form_object.save
        flash[:notice] = 'Tag Group was successfully created.'
        format.html { redirect_to(@form_object.tag_group) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def tag_group_form_object_params
    params.require(:tag_group).permit(:name, :oligos_text, :adapter_type_id)
  end
end
