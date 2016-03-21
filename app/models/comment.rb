#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.

class Comment < ActiveRecord::Base
  # include Uuid::Uuidable
  belongs_to :commentable, :polymorphic => true
  has_many :comments, :as => :commentable
  belongs_to :user

  scope :for_plate, ->(plate) {

    submissions = plate.all_submission_ids

    # Warning: The code below is utterly horrible, and has already be the source of several bugs
    # It needs to be completely re-thought. The main difficulties are:
    # Comments can be both on the requests or on the plate itself
    # Rails handles counts on group statements strangely (See the Comments proxy on plate)

    if submissions.present?
      rids = Request.find(:all,:select=>'id',:conditions=>{:submission_id=>submissions}).map(&:id)
      where([
        '(commentable_type= "Request" AND commentable_id IN (?)) OR (commentable_type = "Asset" and commentable_id = ?)',
        rids,plate.id
      ]).group('CONCAT(comments.description, IFNULL(comments.title,""), comments.user_id)')
      # The above group by is grim, and is due to the way rails generates the key to help count
      # grouped statements. Essentially is adds AS on the end to create a new column. If we don't
      # concat, then if just uses the last element. The IFNULL is necessary as it seems that
      # if any element of a CONCAT statement is NULL, MySQL just returns NULL
    else
      where(['comments.commentable_type = "Asset" and commentable_id = ?', plate.id])
    end

  }

  scope :include_uuid, -> { where('TRUE') }

  def self.counts_for(commentables)
    return 0 if commentables.empty?
    type = commentables.first.class.base_class.name
    where(:commentable_type=>type,:commentable_id=>commentables).group(:commentable_id).count
  end

end

