# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Paged
  def self.page_accessor(action, will_paginate_method, default_value = nil)
    lambda do |object|
      page = object.send(will_paginate_method) || default_value
      page.nil? ? nil : [action, [1, page].max]
    end
  end

  ACTION_NAME_TO_PAGE_METHOD = [
    page_accessor(:last, :total_pages, 1),
    page_accessor(:previous, :previous_page),
    page_accessor(:next, :next_page),
    page_accessor(:read, :current_page, 1)
  ].freeze

  def actions(object, options)
    super.tap { |actions| actions.merge!(pages_to_actions(object, options)) if options[:handled_by] == self }
  end
  private :actions

  def action_updates_for(options)
    response = options[:response]
    return unless response.handled_by == self

    yield(pages_to_actions(response.object, options))
  end
  private :action_updates_for

  def pages_to_actions(object, options)
    first_page = { first: core_path(1, options) }
    ACTION_NAME_TO_PAGE_METHOD.each_with_object(first_page) do |page_method, pages|
      action, page = page_method.call(object)
      next unless action

      pages[action] = core_path(page, options)
    end
  end
  private :pages_to_actions

  def handler_for(segment)
    /^\d+$/.match?(segment.to_s) ? self : super
  end
  private :handler_for

  def page_of_results(target, page = 1, model = target)
    raise ActiveRecord::RecordNotFound, 'before the start of the results' if page <= 0

    target
      .paginate(page: page, per_page: results_per_page, total_entries: model.count(:all))
      .tap do |results|
        raise ActiveRecord::RecordNotFound, 'past the end of the results' if (page > 1) && (page > results.total_pages)
      end
  end
  private :page_of_results

  class PagedTarget
    def initialize(model)
      @model = model
    end

    delegate :count, to: :@model

    class PageOfResults
      def initialize(page, _total, per_page)
        @page, @total_pages = page, page / per_page
      end

      attr_reader :page, :total_pages
      alias current_page page

      def next_page
        page + 1
      end

      def previous_page
        page - 1
      end
    end

    def paginate(options)
      PageOfResults.new(options[:page], options[:total_entries], options[:per_page])
    end
  end

  def count_of_pages(target, page = 1)
    page_of_results(PagedTarget.new(target), page)
  end
  private :count_of_pages

  # For a convenience allow people to override the number of results that are returned per page.  This is
  # really only used in the Cucumber features where we want to see more or less than the defaults.
  mattr_accessor :results_per_page
  self.results_per_page = 100
end
