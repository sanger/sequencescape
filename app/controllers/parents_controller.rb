# frozen_string_literal: true

# Nested under receptacles controller, redirects the user to the upstream asset, or
# provides a disambiguation page if there are multiple.
# Used by clients of the ML Warehouse to provide links to multiplexed library tubes
# without us needing to expose the id of the library tube itself.
# (Or for the user to track it)
# Note: Parents go via requests here, not transfer requests or asset links.
class ParentsController < ApplicationController
  def show
    @child = child
    @parents = @child.source_receptacles

    if @parents.empty?
      render :show, status: :not_found
    elsif @parents.one?
      redirect_to receptacle_path(@parents.first)
    else
      render :show, status: :multiple_choices
    end
  end

  private

  def child
    Receptacle.find(params[:receptacle_id])
  end
end
