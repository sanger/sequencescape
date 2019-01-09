class Comment < ApplicationRecord
  # include Uuid::Uuidable
  belongs_to :commentable, polymorphic: true, required: true
  has_many :comments, as: :commentable
  belongs_to :user

  after_create :trigger_commentable_callback

  scope :for_asset_and_requests, ->(asset, requests) {
    where(commentable_type: 'Request', commentable_id: requests)
      .or(where(commentable: asset))
      .create_with(commentable: asset)
      .select(
        # We need to describe how we select values which aren't included in the group by
        # This is required with default configurations of MySQL 5.7 and ensures reproducible
        # queries with other set-ups.
        ['MIN(id) AS id', :title, :user_id, :description, 'MIN(created_at) AS created_at', 'MIN(updated_at) AS updated_at']
      ).group(:description, :title, :user_id)
  }

  scope :include_uuid, -> { all }

  # Caution, only works for a single class
  def self.counts_for(commentables)
    where(commentable: commentables).group(:commentable_id).count
  end

  private

  ##
  # We add the comments to each submission to ensure that are available for all the requests.
  # At time of writing, submissions add comments to each request, so there are a lot of comments
  # getting created here. We should consider either storing comments on submissions, orders,
  # or having a many-to-many relationship.
  def trigger_commentable_callback
    commentable.after_comment_addition(self)
  end
end
