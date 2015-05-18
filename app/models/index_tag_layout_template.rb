#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
# Index Tag Layouts apply a single index tag to the entire plate
class IndexTagLayoutTemplate < ActiveRecord::Base
  include Uuid::Uuidable
  include Lot::Template

  belongs_to :tag
  validates_presence_of :tag

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :include_tag, :include => :tag

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    ## TODO
  end

  def stamp_to(_)
    # Do Nothing
  end
end
