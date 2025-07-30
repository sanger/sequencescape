# frozen_string_literal: true
class LabSearchesController < ApplicationController
  include SearchBehaviour

  alias new search

  def index
    redirect_to action: :new
  end

  private

  def perform_search(query)
    @batches = Batch.for_search_query(query).to_a
    @assets =
      (
        Labware.for_search_query(query).for_lab_searches_display.to_a +
          Labware.with_barcode(query).for_lab_searches_display.to_a
      ).uniq
  end
end
