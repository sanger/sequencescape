# frozen_string_literal: true

# Provides helper functionality for UAT
class UatActionsController < ApplicationController
  before_action :check_environment
  before_action :find_uat_action_class, only: %i[show create]
  before_action :login_required, except: :create

  skip_before_action :verify_authenticity_token

  def index
    @uat_actions = UatActions.all
  end

  def show
    @uat_action = @uat_action_class.default
  end

  def create
    respond_to do |format|
      @uat_action = @uat_action_class.new(uat_action_params)
      if @uat_action.save
        format.html { render :create }
        format.json { render json: @uat_action.report, status: :created }
      else
        format.html { render :show }
        format.json { render json: @uat_action.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def find_uat_action_class
    @uat_action_class =
      UatActions.find(params[:id]) || raise(ActionController::RoutingError, "No UAT action: #{params[:id]}")
  end

  def uat_action_params
    uat_action = params.fetch(:uat_action, {})
    uat_action.blank? ? {} : uat_action.permit(@uat_action_class.permitted)
  end

  def check_environment
    return unless Rails.env.production?

    redirect_back_or_to root_path, flash: {
      error: 'UAT actions cannot be performed in the production version of Sequencescape.'
    }
  end
end
