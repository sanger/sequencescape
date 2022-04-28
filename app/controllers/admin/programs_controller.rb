# frozen_string_literal: true
class Admin::ProgramsController < ApplicationController # rubocop:todo Style/Documentation
  authorize_resource
  before_action :discover_program, only: %i[show edit update destroy]

  def index
    @programs = Program.all
  end

  def show; end

  def new
    @program = Program.new
  end

  def edit; end

  def create
    @program = Program.new(program_params)

    respond_to do |format|
      if @program.save
        flash[:notice] = 'Program was successfully created.'
        format.html { redirect_to(admin_program_path(@program)) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @program.update(program_params)
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
