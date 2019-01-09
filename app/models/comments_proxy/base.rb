# frozen_string_literal: true

# Some resource need to collate comments via a variety of sources and de-duplicate
# them. CommentsProxies deal with this behaviour and isolate it.
module CommentsProxy
  # Base object handling comment proxies. Subclasses should impliment #request_ids
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
      @comment_assn ||= Comment.where(commentable_type: 'Request', commentable_id: request_ids)
                               .or(Comment.where(commentable: @commentable))
                               .create_with(commentable: @commentable)
                               .select(
                                 # We need to describe how we select values which aren't included in the group by
                                 # This is required with default configurations of MySQL 5.7 and ensures reproducible
                                 # queries with other set-ups.
                                 ['MIN(id) AS id', :title, :user_id, :description, 'MIN(created_at) AS created_at', 'MIN(updated_at) AS updated_at']
                               ).group(:description, :title, :user_id)
    end

    # We're using group above, resulting in size and count returning a hash, not a count.
    def size(*args)
      comment_assn.size(*args).length
    end

    def count(*_args)
      comment_assn.count(:all).length
    end

    private

    def request_ids
      raise 'Must be implimented on subclass'
    end
  end
end
