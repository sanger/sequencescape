class Comment < ApplicationRecord
  # include Uuid::Uuidable
  belongs_to :commentable, polymorphic: true, optional: false
  has_many :comments, as: :commentable
  belongs_to :user

  after_create :trigger_commentable_callback

  scope :include_uuid, -> { all }

  # Caution, only works for a single class
  def self.counts_for(commentables)
    where(commentable: commentables).group(:commentable_id).count
  end

  def can_be_deleted_by?(deleting_user)
    user == deleting_user || user.administrator?
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
