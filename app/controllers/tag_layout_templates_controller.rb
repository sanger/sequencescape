# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class TagLayoutTemplatesController < ApplicationController
  DIRECTIONS = {
    'InColumns (A1,B1,C1...)': 'TagLayout::InColumns',
    'InRows (A1,A2,A3...)': 'TagLayout::InRows',
    'InInverseColumns (H12,G12,F12...)': 'TagLayout::InInverseColumns',
    'InInverseRows (H12,H11,H10...)': 'TagLayout::InInverseRows'
  }.freeze

  before_action :admin_login_required, only: %i[new create update]

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
    @tag_layout_template = TagLayoutTemplate.new(tag_group_id: params[:tag_group_id])
    @direction_algorithms = DIRECTIONS

    respond_to do |format|
      format.html
    end
  end

  def create
    @tag_layout_template = TagLayoutTemplate.new(tag_layout_template_params)

    respond_to do |format|
      if @tag_layout_template.save
        flash[:notice] = 'Tag Layout Template was successfully created.'
        format.html { redirect_to(@tag_layout_template) }
      else
        @direction_algorithms = DIRECTIONS
        format.html { render action: 'new' }
      end
    end
  end

  def tag_layout_template_params
    params.require(:tag_layout_template).permit(:name, :tag_group_id, :tag2_group_id, :direction_algorithm, :walking_algorithm)
  end
end
