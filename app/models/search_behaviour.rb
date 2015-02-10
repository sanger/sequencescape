#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014 Genome Research Ltd.
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
