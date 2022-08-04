# frozen_string_literal: true

# Provides helper functionality for Support
# Note: there is a slight deviation away from the standard setup here as
# we split our new action into two stages. The first presents us with a list
# of possible actions, and then we render the actual form.
class SupportActionsController < ApplicationController
  authorize_resource SupportAction

  def index
    @support_actions = SupportActions.all
  end

  # We have an action specified, so render the form
  def new_action
    @support_action = SupportAction.new(action: params[:action_id])
    @url_helpers = Rails.application.config_for(:support_actions_urls)
    raise ActiveRecord::RecordNotFound, "No support action #{params[:action_id]}" unless @support_action.action_class
  end

  # We don't have an action specified, so simply render the list of all actions.
  def new
    @support_actions = SupportActions.all
  end

  def show
    @support_action = SupportAction.find(params[:id])
  end

  def create
    @url_helpers = Rails.application.config_for(:support_actions_urls)
    @support_action = SupportAction.new(user: current_user, urls: url_params, **support_action_params)

    if @support_action.perform
      redirect_to @support_action
    else
      render :new_action
    end
  end

  private

  def url_params
    params.require(:support_action).fetch(:url_values, {}).to_unsafe_hash # We're not doing anything risky here
      .filter_map do |type, options|
      next if options.values.all?(&:blank?)
      url_options = options.symbolize_keys
      url_options.default = ''
      {
        type: type,
        options: options,
        url: url_config(type.to_sym, :url_template) % url_options,
        name: url_config(type.to_sym, :name_template) % url_options
      }
    end
  end

  def support_action_params
    params.require(:support_action).permit(:action, options: {})
  end

  def url_config(*args)
    Rails.application.config_for(:support_actions_urls).dig(*args) || ''
  end
end
