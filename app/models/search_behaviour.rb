module SearchBehaviour
  MINIMUM_QUERY_LENGTH = 3

  def self.included(base)
    base.helper_method :each_non_empty_search_result
  end

  def search
    t = Time.now
    @query = params[:q]
    perform_search(params[:q].strip) unless params[:q].blank? || query_invalid?
    @search_took = Time.now - t
    @render_start = Time.now
    respond_to do |format|
      format.html
      format.js { render partial: 'search', layout: false }
    end
  end

  private

  def perform_search(query)
    searchable_classes.each do |clazz|
      clazz_search(clazz, query)
    end
  end

  def clazz_search(clazz, query)
    instance_variable_set("@#{clazz.name.underscore.pluralize}", clazz_query(clazz, query).to_a)
  end

  def clazz_query(clazz, query)
    clazz.for_search_query(query)
  end

  def each_non_empty_search_result
    searchable_classes.each do |clazz|
      results = instance_variable_get("@#{clazz.name.underscore.pluralize}")
      yield(clazz.name.underscore, results) unless results.blank?
    end
  end

  def query_invalid?
    return false if params[:q].length >= MINIMUM_QUERY_LENGTH

    flash.now[:error] = "Queries should be at least #{MINIMUM_QUERY_LENGTH} characters long"
  end
end
