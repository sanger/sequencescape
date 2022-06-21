# frozen_string_literal: true

# Controller for the Advanced Search page.
# This was initially made to handle searches for Custom Metadata,
# but the ambition is to consolidate all Sequencescape search functionality into this one page.
class AdvancedSearchController < ApplicationController
  attr_reader :searched, :results, :key_search_term, :value_search_term

  def index
    @searched = false
    @results = []
    @key_search_term = nil
    @value_search_term = nil
  end

  def search
    @key_search_term = params['metadata_key']
    @value_search_term = params['metadata_value']

    if key_search_term.present? && value_search_term.present?
      @results = CustomMetadatum.where(key: key_search_term, value: value_search_term)
    end

    # else  @results = [] # it gets set to nil anyway - not sure how
    @searched = true

    render :index
  end
end
