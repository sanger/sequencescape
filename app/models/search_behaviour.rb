# frozen_string_literal: true
module SearchBehaviour
  MINIMUM_QUERY_LENGTH = 3

  def self.included(base)
    base.helper_method :each_non_empty_search_result
    base.helper_method :no_results?
  end

  def search # rubocop:todo Metrics/AbcSize
    t = Time.zone.now
    @query = params[:q]
    perform_search(params[:q].strip) unless params[:q].blank? || query_invalid?
    @search_took = Time.zone.now - t
    @render_start = Time.zone.now

    respond_to do |format|
      format.html
      format.js { render partial: 'search', layout: false }
    end
  end

  private

  def perform_search(query)
    searchable_classes.each { |clazz| clazz_search(clazz, query) }
  end

  def clazz_search(clazz, query)
    instance_variable_set(:"@#{clazz.name.underscore.pluralize}", clazz_query(clazz, query).to_a)
  end

  def clazz_query(clazz, query)
    clazz.for_search_query(query)
  end

  def each_non_empty_search_result
    searchable_classes.each do |clazz|
      results = instance_variable_get(:"@#{clazz.name.underscore.pluralize}")
      yield(clazz.name.underscore, results) if results.present?
    end
  end

  def no_results?
    searchable_classes.all? { |clazz| instance_variable_get(:"@#{clazz.name.underscore.pluralize}").blank? }
  end

  def query_invalid?
    return false if params[:q].length >= MINIMUM_QUERY_LENGTH

    flash.now[:error] = "Queries should be at least #{MINIMUM_QUERY_LENGTH} characters long"
  end
end
