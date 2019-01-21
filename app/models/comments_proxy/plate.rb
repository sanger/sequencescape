# frozen_string_literal: true

# Plate comments are a mess
# - You can have comments on the plate itself.
# - But 90% of the time you want comments on the requests associated with the plate
# - Except these aren't event directly associated with the plate
# - Or even the wells on the plate.
# - Instead they come from wells further upstream
# - Oh, and typically all requests in a submission have identical comments
# - But showing the same comment to the user 96 times is just confusing
# - So we have a special scope to find comments.
# - And to add them
# - And then the API chokes when it tries to display the comment count, as it doesn't
#   understand group by.
# - So we hack that
# - And then we weep every time anything changes
# - It would be vastly easier if comments just sat on submissions
# - Although even then we'd need to copy them across if work is re-requested.
class CommentsProxy::Plate < CommentsProxy::Base
  private

  def request_ids
    @commentable.well_requests_as_source.ids.presence ||
      @commentable.in_progress_requests.ids.presence ||
      # This is a final fallback to support legacy plates prior to request on aliquot
      Request.where(submission_id: @commentable.all_submission_ids).ids
  end
end
