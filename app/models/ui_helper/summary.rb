# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.
# Ideally we'd convert this into a scope/association, but its complicated by the need to associate across
# two models, one of which we're trying to deprecate.
require 'will_paginate/array'

module UiHelper
  class Summary
    attr_accessor :summary_items
    attr_accessor :current_page

    def initialize(options = {})
      @summary_items = []
      @current_page  = options[:page].to_i || 1
      @item_per_page = options[:per_page].to_i || 10
    end

    def load(study, workflow)
      study.submissions_for_workflow(workflow).each do |submission|
        submission.events.where('message LIKE "Run%"').find_each do |event|
          load_event(event)
        end
      end
      load_study(study)
      summaries
    end

    delegate :size, to: :summary_items

    def load_asset(asset)
      asset.events_on_requests.where('message LIKE "Run%"').find_each do |event|
        load_event(event)
      end
    end

    def load_event(event)
      add(SummaryItem.new(
        message: event.message,
        object: event.eventful,
        timestamp: event.created_at,
        external_message: "Run #{event.identifier}",
        external_link: "#{configatron.run_information_url}#{event.identifier}"
      ))
    end

    def load_study(study)
      study.events.find_each do |event|
        add(SummaryItem.new(
          message: event.message,
          object: study,
          timestamp: event.created_at,
          external_message: "Study #{study.id}",
          external_link: ''
        ))
      end
    end

    def summaries
      summary_items.sort_by(&:timestamp).reverse
    end

    def add(item)
      @summary_items << item
    end

    def size
      @summary_items.size
    end
  end
end
