# frozen_string_literal: true
class Admin::RolesController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource

  def index
    @roles = Role.group(:name).pluck(:name)

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @roles }
    end
  end

  def show
    @role = Role.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @role }
    end
  end

  def new
    @role = Role.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @role }
    end
  end

  def create # rubocop:todo Metrics/MethodLength
    @role = Role.new(params[:role])

    respond_to do |format|
      if @role.save
        flash[:notice] = 'Role was successfully created.'
        format.html { redirect_to(@role) }
        format.xml { render xml: @role, status: :created, location: @role }
      else
        format.html { render action: 'new' }
        format.xml { render xml: @role.errors, status: :unprocessable_entity }
      end
    end
  end
end
