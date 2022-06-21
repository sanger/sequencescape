# frozen_string_literal: true

# Controller for the Advanced Search page.
# This was initially made to handle searches for Custom Metadata,
# but the ambition is to consolidate all Sequencescape search functionality into this one page.
class AdvancedSearchController < ApplicationController
  def index
    @searched = false
    parse_params
  end

  def search
    @searched = true
    parse_params

    if @key_search_term.present? && @value_search_term.present?
      @results = CustomMetadatum.where(key: @key_search_term, value: @value_search_term)
    end

    render :index
  end

  def parse_params
    @key_search_term = params['metadata_key']
    @value_search_term = params['metadata_value']
  end
end
