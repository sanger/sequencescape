#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.
class Comment < ActiveRecord::Base
  # include Uuid::Uuidable
  belongs_to :commentable, :polymorphic => true
  has_many :comments, :as => :commentable
  belongs_to :user

  named_scope :for_plate, lambda { |plate|

    submissions = plate.all_submission_ids

    if submissions.present?
      {
        :select => 'DISTINCT comments.description, comments.title, comments.user_id',
        :joins => "LEFT JOIN requests AS r ON r.id = comments.commentable_id AND comments.commentable_type = 'Request'",
        :conditions => ['r.submission_id IN (?) OR (comments.commentable_type = "Asset" and commentable_id = ?)',submissions.join(','),plate.id]
      }
    else
      {
        :conditions => ['comments.commentable_type = "Asset" and commentable_id = ?', plate.id]
      }
    end

  }

  named_scope :include_uuid, {} # BLUFF!

end
