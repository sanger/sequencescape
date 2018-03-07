# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class TagGroupsController < ApplicationController
  before_action :admin_login_required, only: [:new, :edit, :create, :update]

  def index
    p 'in index'
    @tag_groups = TagGroup.all

    respond_to do |format|
      format.html
    end
  end

  def show
    p 'in show'
    @tag_group = TagGroup.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    p 'in new'
    @tag_group = TagGroup.new

    respond_to do |format|
      format.html
    end
  end

  # def edit
  #   @tag_group = TagGroup.find(params[:id])
  # end

  def create
    p 'in create'
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

  # def update
  #   @tag_group = TagGroup.find(params[:id])

  #   respond_to do |format|
  #     if @tag_group.update_attributes(tag_group_params)
  #       flash[:notice] = 'Tag Group was successfully updated.'
  #       format.html { redirect_to(@tag_group) }
  #     else
  #       format.html { render action: 'edit' }
  #     end
  #   end
  # end

  def tag_group_params
    p 'in tag_group_params'
    params.require(:tag_group).permit(:name,:oligos_text)
  end

  # Permits oligos text
  # def tag_params
    # params.permit(tags: [:map_id, :oligo])
    #       .fetch(:tags, {})                                           # fetch returns a parameter for the given key
    #       .reject { |_index, attributes| attributes[:oligo].blank? }  # returns a new Parameters instance with things that evalute to true in the block removed (i.e. blank oligos)
    #       .values.map(&:to_h)                                         # returns a safe hash representation of the parameters with unpermitted keys removed
  # end

  def tag_params
    p 'in tag_params'
    @tag_group.oligos_text.split(/\s+/).each_with_index.map { |oligo, i| { oligo: oligo, map_id: i+1 } } unless @tag_group.oligos_text.nil?
  end
end
