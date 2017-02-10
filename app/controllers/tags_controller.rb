# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class TagsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :admin_login_required, only: [:edit, :update]
  before_action :find_tag_group
  before_action :find_tag_by_id, only: [:show, :edit, :update]

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Tag was successfully updated.'
        format.html { redirect_to(@tag_group) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

    def find_tag_group
      @tag_group = TagGroup.find(params[:tag_group_id])
    end

    def find_tag_by_id
      @tag = Tag.find(params[:id])
    end
end
