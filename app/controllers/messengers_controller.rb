# frozen_string_literal: true

# Controller for debug purposes. Returns the Messenger payload, allows easy
# checking of messenger content
class MessengersController < ApplicationController
  def show
    @messenger = Messenger.find(params[:id])
    render json: @messenger
  end
end
