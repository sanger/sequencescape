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
    @number_of_tags = params[:number_of_tags]
    @tag_group = TagGroup.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @tag_group = TagGroup.find(params[:id])
  end

  def create
    @tag_group = TagGroup.new(tag_group_params)
    @tags = @tag_group.tags.build(tag_params)

    respond_to do |format|
      if @tag_group.save
        flash[:notice] = 'Tag Group was successfully created.'
        format.html { redirect_to(@tag_group) }
      else
        format.html { redirect_to(@tag_group) }
      end
    end
  end

  def update
    @tag_group = TagGroup.find(params[:id])

    respond_to do |format|
      if @tag_group.update_attributes(tag_group_params)
        flash[:notice] = 'Tag Group was successfully updated.'
        format.html { redirect_to(@tag_group) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def tag_group_params
    params.require(:tag_group).permit(:name)
  end

  # Permits oligo and mapi_id, filters out any unfilled fields
  def tag_params
    params.fetch(:tags, []).reject do |_index, attributes|
      attributes[:oligo].blank?
    end.map do |_index, attributes|
      attributes.permit(:map_id, :oligo)
    end
  end
end
