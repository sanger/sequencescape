# frozen_string_literal: true

# When displaying tube rack comments, we also want to show any comments
# associated with the contained tubes, or their requests.
class CommentsProxy::TubeRack < CommentsProxy::Base
  def add_comment_to_tubes(comment)
    comment_records =
      @commentable.tubes.ids.map do |tube_id|
        {
          commentable_type: 'Labware',
          commentable_id: tube_id,
          **comment.attributes.except('id', 'commentable_type', 'commentable_id')
        }
      end

    # NOTE: We use import here to bypass the after_create
    # callbacks on Comment, as the rack has already handled that.
    # If we let the tubes handle it, we'd have lots of duplicate
    # comments.
    Comment.import(comment_records)
  end

  private

  # For tube racks, not only do we want
  # the rack itself, but all its tubes
  def labware_query
    Comment.where(commentable_type: 'Labware', commentable_id: [@commentable.id, *@commentable.tubes.ids])
  end

  # We grab requests both on the tube aliquots, *and* out of the tubes
  # themselves.
  def request_ids
    @commentable.requests_as_source.ids + @commentable.aliquots.where.not(request_id: nil).distinct.pluck(:request_id)
  end
end
