# frozen_string_literal: true
# A pipeline that has its inbox grouped by submission needs to provide specific paging capabilities.
# All requests for a submission must appear on the same page, i.e. if a submission has 200 requests
# and there are only 100 allowed per page, then all of these requests must appear on a page and not
# across two.
module Pipeline::InboxGroupedBySubmission
  def self.included(base)
    # rubocop:todo Rails/HasManyOrHasOneDependent
    base.has_many :inbox, class_name: 'Request', extend: [Pipeline::RequestsInStorage]

    # rubocop:enable Rails/HasManyOrHasOneDependent
    base.group_by_submission = true
    base.request_sort_order = { submission_id: :desc, id: :asc }.freeze
  end

  private

  def grouping_parser
    GrouperBySubmission.new(self)
  end
end
