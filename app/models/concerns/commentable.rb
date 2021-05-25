# frozen_string_literal: true

# Classes including this module can have comments attached to them
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy, inverse_of: :commentable
    scope :with_comments, -> { joins(:comments) } do
      def group(ids)
        conditions = {}
        conditions[:id] = ids if ids

        group(:commentable_id).where(conditions).count
      end
    end
  end

  class_methods do
    def get_comment_count(ids = nil)
      h = Hash.new(0) # return 0 if key is not in the hash
      with_comments.group(ids).each { |commentable_id, comment_count| h[commentable_id.to_i] = comment_count }
      h
    end
  end

  def after_comment_addition(_comment)
    # Override this functionality in classes which include Commentable to customize behaviour
    # Can't use association callbacks, as need to support comments created directly eg.
    # Comment.create(description: 'This should work', commentable: plate)
  end
end
