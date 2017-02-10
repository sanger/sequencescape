# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Admin::FacultySponsorsController < ApplicationController
# WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
# It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :admin_login_required
  before_action :discover_faculty_sponsor, only: [:show, :edit, :update, :destroy]

  def index
    @faculty_sponsors = FacultySponsor.all
  end

  def show
  end

  def new
    @faculty_sponsor = FacultySponsor.new
  end

  def edit
  end

  def create
    @faculty_sponsor = FacultySponsor.new(params[:faculty_sponsor])

    respond_to do |format|
      if @faculty_sponsor.save
        flash[:notice] = 'Faculty Sponsor was successfully created.'
        format.html { redirect_to(admin_faculty_sponsors_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @faculty_sponsor.update_attributes(params[:faculty_sponsor])
        flash[:notice] = 'Faculty Sponsor was successfully updated.'
        format.html { redirect_to(admin_faculty_sponsors_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @faculty_sponsor.destroy

    respond_to do |format|
      flash[:notice] = 'Faculty Sponsor was successfully deleted.'
      format.html { redirect_to(admin_faculty_sponsors_path) }
    end
  end

  private

  def discover_faculty_sponsor
    @faculty_sponsor = FacultySponsor.find(params[:id])
  end
end
