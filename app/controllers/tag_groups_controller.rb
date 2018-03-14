# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class TagGroupsController < ApplicationController
  before_action :admin_login_required, only: [:new, :edit, :create, :update]

  def index
    @tag_groups = TagGroup.all

    respond_to do |format|
      format.html
    end
  end

  def show
    @tag_group = TagGroup.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    @form_object = TagGroup::FormObject.new

    respond_to do |format|
      format.html
    end
  end

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
    params.require(:tag_group).permit(:name, :oligos_text)
  end
end
