# frozen_string_literal: true

# PickLists are a wrapper around {Submission} and {Batch} for the
# {CherrypickPipeline}. The controller provides an index for quick
# overview, and show pages to provide a shareable link if the
# submission is built asynchronously.
class PickListsController < ApplicationController
  # Paginated list of all PickLists
  def index
    @pick_lists = PickList.order(id: :desc).page(params[:page])
  end

  def show
    @pick_list = PickList.find(params[:id])
  end
end
