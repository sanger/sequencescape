# frozen_string_literal: true

# Provides helper functionality for UAT
class UatActionsController < ApplicationController
  before_action :check_environment
  before_action :find_uat_action_class, only: %i[show create]

  def index
    @uat_actions = UatActions.all
  end

  def show
    @uat_action = @uat_action_class.default
  end

  def create
    @uat_action = @uat_action_class.new(uat_action_params)
    if @uat_action.save
      render :create
    else
      render :show
    end
  end

  private

  def find_uat_action_class
    @uat_action_class = UatActions.find(params[:id])
  end

  def uat_action_params
    params.require(:uat_action).permit(@uat_action_class.permitted)
  end

  def check_environment
    return unless Rails.env.production?

    redirect_back fallback_location: root_path, flash: {
      error: 'UAT actions cannot be performed in the production version of Sequencescape.'
    }
  end
end
