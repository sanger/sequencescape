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
      rids = Request.find(:all,:select=>'id',:conditions=>{:submission_id=>submissions}).map(&:id)
      {
        :conditions => ['(commentable_type= "Request" AND commentable_id IN (?)) OR (commentable_type = "Asset" and commentable_id = ?)',rids,plate.id],
        :group => 'comments.description, comments.title, comments.user_id'
      }
    else
      {
        :conditions => ['comments.commentable_type = "Asset" and commentable_id = ?', plate.id]
      }
    end

  }

  named_scope :include_uuid, {} # BLUFF!

end

