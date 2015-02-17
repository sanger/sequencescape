#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2014 Genome Research Ltd.
class Item < ActiveRecord::Base
  include Uuid::Uuidable
  include EventfulRecord
  include Workflowed
  extend EventfulRecord
  has_many_events
  has_many_lab_events

  @@cached_requests = nil

  belongs_to :submission
  belongs_to :study

  has_many :requests, :dependent => :destroy
  has_many :comments, :as => :commentable

  validates_presence_of :version
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:workflow_id, :version], :on => :create, :message => "already in use (item)"

  named_scope :for_search_query, lambda { |query,with_includes|
    { :conditions => [ 'name LIKE ? OR id=?', "%#{query}%", query ] }
  }

  def before_validation_on_create
    # TODO - Extract code to a shared library
    things_with_same_name = self.class.all(:conditions => {:name => self.name, :workflow_id => self.workflow_id})
    if things_with_same_name.empty?
      self.increment(:version)
    else
      self.write_attribute :version, (things_with_same_name.size + 1)
    end
  end
end
