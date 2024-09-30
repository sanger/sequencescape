# frozen_string_literal: true

# Some resource need to collate comments via a variety of sources and de-duplicate
# them. CommentsProxies deal with this behaviour and isolate it.
module CommentsProxy
  # Base object handling comment proxies. Subclasses should implement #request_ids
  class Base
    delegate_missing_to :comment_assn

    def initialize(commentable)
      @commentable = commentable
    end

    # Keep all this away from the comment class itself.
    # - Finds any comments associated with the asset
    # - OR with any requests returned by request_ids
    # - Then group them together to perform de-duplication
    def comment_assn
      @comment_assn ||=
        Comment
          .where(commentable_type: 'Request', commentable_id: request_ids)
          .or(labware_query)
          .create_with(commentable: @commentable)
          .select(
            # We need to describe how we select values which aren't included in the group by
            # This is required with default configurations of MySQL 5.7 and ensures reproducible
            # queries with other set-ups.
            [
              'MIN(id) AS id',
              :title,
              :user_id,
              :description,
              'MIN(created_at) AS created_at',
              'MIN(updated_at) AS updated_at'
            ]
          )
          .group(:description, :title, :user_id)
    end

    # We're using group above, resulting in size and count returning a hash, not a count.
    def size(*)
      comment_assn.size(*).length
    end

    def count(*_args)
      comment_assn.count(:all).length
    end

    def add_comment_to_submissions(comment)
      Submission
        .where(id: submission_ids)
        .find_each { |submission| submission.add_comment(comment.description, comment.user, comment.title) }
    end

    def labware_query
      Comment.where(commentable: @commentable)
    end

    private

    def submission_ids
      Request.where(id: request_ids).uniq.pluck(:submission_id).compact
    end

    def request_ids
      raise 'Must be implemented on subclass'
    end
  end
end
