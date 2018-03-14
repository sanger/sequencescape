# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class TagLayoutTemplatesController < ApplicationController
  before_action :admin_login_required, only: [:new, :create, :update]

  def index
    @tag_layout_templates = TagLayoutTemplate.all

    respond_to do |format|
      format.html
    end
  end

  def show
    @tag_layout_template = TagLayoutTemplate.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    @form_object = TagLayoutTemplate::FormObject.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @form_object = TagLayoutTemplate::FormObject.new(tag_layout_template_form_object_params)

    respond_to do |format|
      if @form_object.save
        flash[:notice] = 'Tag Layout Template was successfully created.'
        format.html { redirect_to(@form_object.tag_layout_template) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def tag_layout_template_form_object_params
    params.require(:tag_layout_template).permit(?) #TODO: what are the params?
  end
end