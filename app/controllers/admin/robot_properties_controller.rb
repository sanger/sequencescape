# frozen_string_literal: true
class Admin::RobotPropertiesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_robot_by_id
  authorize_resource

  def index
    @robot_properties = @robot.robot_properties
  end

  def show
    @robot_property = @robot.robot_properties.find(params[:id])
  end

  def print_labels
    @robot_property = @robot.robot_properties.beds.find(params[:id])
    if LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::RobotBeds, [@robot_property]).execute
      flash[:now] = 'The barcode for the bed was correctly printed'
    end
    redirect_to [:admin, @robot, @robot_property]
  end

  def new
    @robot_property = @robot.robot_properties.build
  end

  def edit
    @robot_property = @robot.robot_properties.find(params[:id])
  end

  def create
    @robot_property = @robot.robot_properties.build(params[:robot_property])
    if @robot_property.save
      redirect_to [:admin, @robot, @robot_property]
    else
      render action: 'new'
    end
  end

  def update
    @robot_property = RobotProperty.find(params[:id])
    if @robot_property.update(params[:robot_property])
      redirect_to [:admin, @robot, @robot_property]
    else
      render action: 'edit'
    end
  end

  def destroy
    @robot_property = RobotProperty.find(params[:id])
    @robot_property.destroy
    respond_to do |format|
      format.html { redirect_to admin_robot_robot_properties_path(@robot) }
      format.xml { head :ok }
    end
  end

  def find_robot_by_id
    @robot = Robot.find(params[:robot_id])
  end
end
