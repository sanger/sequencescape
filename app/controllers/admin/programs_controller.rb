# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
class Admin::ProgramsController < ApplicationController
  before_action :admin_login_required
  before_action :discover_program, only: [:show, :edit, :update, :destroy]

  def index
    @programs = Program.all
  end

  def show
  end

  def new
    @program = Program.new
  end

  def edit
  end

  def create
    @program = Program.new(program_params)

    respond_to do |format|
      if @program.save
        flash[:notice] = 'Program was successfully created.'
        format.html {  redirect_to(admin_program_path(@program)) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @program.update_attributes(program_params)
        flash[:notice] = 'Program was successfully updated.'
        format.html { redirect_to(admin_programs_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def discover_program
    @program = Program.find(params[:id])
  end

  def program_params
    params.require(:program).permit(:name)
  end
end
