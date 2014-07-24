# A pipeline that has its inbox grouped by submission needs to provide specific paging capabilities.
# All requests for a submission must appear on the same page, i.e. if a submission has 200 requests
# and there are only 100 allowed per page, then all of these requests must appear on a page and not
# across two.
module Pipeline::InboxGroupedBySubmission
  def self.included(base)
    base.has_many :inbox, :class_name => 'Request', :extend => [ Pipeline::RequestsInStorage, Pagination ]
  end

  # Always group by submission
  def group_by_submission?
    true
  end

  # This module overrides the behaviour of will_paginate so that the requests for an individual
  # submission appear on the same page.  It does this by first paging the submission IDs, and then
  # limiting the query so that it only includes requests from these submissions.
  module Pagination
    def paginate(*args)
      super(*args.push(args.extract_options!.merge(:finder => :paginated_by_submission, :total_entries => submissions(:count))))
    end

    def paginated_by_submission(*args)
      options                      = args.extract_options!
      options_for_submission_query = Hash[[ :limit, :offset ].map { |k| [ k, options.delete(k) ] if options.key?(k) }.compact]
      all(options.deep_merge(:conditions => { :submission_id => submissions(:all, options_for_submission_query).map(&:submission_id) }))
    end

    #--
    # Slight hack here in that we are assuming that only the submissions that have requests
    # waiting in the correct location and in the right state are what we want to display
    # for the inbox.
    #++
    def submissions(finder_method, options = {})
      with_exclusive_scope do
        ready_in_storage.full_inbox.send(finder_method, options.merge(:select => 'DISTINCT submission_id', :order => 'submission_id ASC'))
      end
    end
    private :submissions
  end
end
