module Core::Endpoint::BasicHandler::Paged
  ACTION_NAME_TO_PAGE_METHOD = {
    :last     => :total_pages,
    :previous => :previous_page,
    :next     => :next_page,
    :read     => :current_page
  }

  def actions(object, options)
    super.tap do |actions|
      actions.merge!(pages_to_actions(object, options)) if options[:handled_by] == self
    end
  end
  private :actions

  def action_updates_for(options)
    response = options[:response]
    return unless response.handled_by == self
    yield(pages_to_actions(response.object, options))
  end
  private :action_updates_for

  def pages_to_actions(object, options)
    action_to_page = ACTION_NAME_TO_PAGE_METHOD.map do |action,will_paginate_method|
      page = object.send(will_paginate_method)
      page.nil? ? nil : [ action, core_path([ 1, page ].max, options) ]
    end
    Hash[action_to_page.compact + [ [:first, core_path(1, options)] ]]
  end
  private :pages_to_actions

  def handler_for(segment)
    (segment.to_s =~ /^\d+$/) ? self : super
  end
  private :handler_for

  def page_of_results(target, page = 1, model = target)
    raise ActiveRecord::RecordNotFound, 'before the start of the results' if page <= 0
    target.paginate(
      :page          => page,
      :per_page      => Core::Endpoint::BasicHandler::Paged.results_per_page,
      :total_entries => model.count
    ).tap do |results|
      raise ActiveRecord::RecordNotFound, 'past the end of the results' if (results.total_pages == 0) and (page > 1)
    end
  end
  private :page_of_results

  # For a convenience allow people to override the number of results that are returned per page.  This is
  # really only used in the Cucumber features where we want to see more or less than the defaults.
  mattr_accessor :results_per_page
  self.results_per_page = 100
end
