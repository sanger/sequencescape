module SearchBehaviour
  def self.included(base)
    base.helper_method :each_non_empty_search_result
  end

  def search
    t = Time.now
    perform_search(params[:q].strip) unless params[:q].blank?
    @search_took = Time.now - t
    @render_start = Time.now
    respond_to do |format|
      format.html
      format.js { render :partial => 'search', :layout => false }
    end
  end

private

  def perform_search(query)
    searchable_classes.each do |clazz|
      instance_variable_set("@#{ clazz.name.underscore.pluralize }", clazz.for_search_query(query,extended).all)
    end
  end

  def each_non_empty_search_result(&block)
    searchable_classes.each do |clazz|
      results = instance_variable_get("@#{ clazz.name.underscore.pluralize }")
      yield(clazz.name.underscore, results) unless results.blank?
    end
  end
end
