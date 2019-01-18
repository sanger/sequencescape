# frozen_string_literal: true

# Tube comments follow a similar proxy pattern to plate comments
class CommentsProxy::Tube < CommentsProxy::Base
  private

  def request_ids
    @commentable.requests_as_source.ids.presence ||
      @commentable.aliquots.where.not(request_id: nil).distinct.pluck(:request_id)
  end
end
