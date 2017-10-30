# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2017 Genome Research Ltd.

class Admin::PrimerSetsController < ApplicationController
  before_action :admin_login_required
  before_action :discover_primer_set, only: [:edit, :update]

  def index
    @primer_sets = PrimerSet.all
  end

  def new
    @primer_set = PrimerSet.new
  end

  def show; end

  def edit; end

  def create
    @primer_set = PrimerSet.new(primer_set_params)

    respond_to do |format|
      if @primer_set.save
        flash[:notice] = "Created '#{@primer_set.name}'"
        format.html { redirect_to(admin_primer_sets_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @primer_set.update_attributes(primer_set_params)
        flash[:notice] = 'Primer Set was successfully updated.'
        format.html { redirect_to(admin_primer_sets_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def discover_primer_set
    @primer_set = PrimerSet.find(params[:id])
  end

  def primer_set_params
    params.require(:primer_set).permit(:name, :snp_count)
  end
end
