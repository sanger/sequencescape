# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Admin::RobotsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_robot_by_id, only: [:show, :edit, :update, :destroy]

  def index
    @robots = Robot.all

    respond_to do |format|
      format.html
      format.xml { render xml: @robots }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @robot }
    end
  end

  def new
    @robot = Robot.new

    respond_to do |format|
      format.html
      format.xml { render xml: @robot }
    end
  end

  def edit
  end

  def create
    @robot = Robot.new(params[:robot])

    respond_to do |format|
      if @robot.save
        flash[:notice] = 'Robot was successfully created.'
        format.html { redirect_to admin_robot_path(@robot) }
        format.xml  { render xml: @robot, status: :created, location: @robot }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @robot.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @robot.update_attributes(params[:robot])
        flash[:notice] = 'Robot was successfully updated.'
        format.html { redirect_to admin_robot_path(@robot) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @robot.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @robot.destroy
    flash[:notice] = 'Robot removed successfully'

    respond_to do |format|
      format.html { redirect_to(admin_robots_url) }
      format.xml  { head :ok }
    end
  end

  def find_robot_by_id
    @robot = Robot.find(params[:id])
  end
end
