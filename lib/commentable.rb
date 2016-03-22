#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Commentable
  def self.included(base)

    base.class_eval do
      has_many :comments, :as => :commentable
      scope :with_comments, -> {  joins(:comments).where("commentable_type = '#{base.name}'") } do
        def group(ids)
          conditions = {}
          if ids
            conditions[:id]=ids
          end

          count(:group => :commentable_id, :conditions => conditions)
        end
      end
      def self.get_comment_count(ids=nil)
        h = Hash.new(0) # return 0 if key is not in the hash
        with_comments.group(ids).each do |commentable_id, comment_count|
          h[commentable_id.to_i]=comment_count
        end
        h
      end
    end
  end

end
