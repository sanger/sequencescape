# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2017 Genome Research Ltd.

class Admin::PrimerPanelsController < ApplicationController
  before_action :admin_login_required
  before_action :discover_primer_panel, only: [:edit, :update]

  def index
    @primer_panels = PrimerPanel.all
  end

  def new
    @primer_panel = PrimerPanel.new(programs: default_programs)
  end

  def show; end

  def edit; end

  def create
    @primer_panel = PrimerPanel.new(primer_panel_params)

    respond_to do |format|
      if @primer_panel.save
        flash[:notice] = "Created '#{@primer_panel.name}'"
        format.html { redirect_to(admin_primer_panels_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @primer_panel.update_attributes(primer_panel_params)
        flash[:notice] = 'Primer Panel was successfully updated.'
        format.html { redirect_to(admin_primer_panels_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def default_programs
    { 'pcr 1' => { 'name' => nil, 'duration' => nil },
      'pcr 2' => { 'name' => nil, 'duration' => nil } }
  end

  def discover_primer_panel
    @primer_panel = PrimerPanel.find(params[:id])
  end

  def primer_panel_params
    params.require(:primer_panel).permit(:name, :snp_count, programs: ['pcr 1': [:name, :duration],
                                                                       'pcr 2': [:name, :duration]])
  end
end
