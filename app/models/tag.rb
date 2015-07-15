#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Tag < ActiveRecord::Base
  module Associations
    def untag!
      aliquots.first.try(:update_attributes!, :tag => nil)
    end
  end

  include Api::TagIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable



  belongs_to :tag_group
  has_many :assets, :as => :material
  has_many :requests, :through => :assets, :uniq => true

  named_scope :sorted , :order => "map_id ASC"

  def name
    "Tag #{map_id}"
  end

  # Creates an instance of this tag that can be attached to a well.
  def create!
    TagInstance.create!(:tag => self)
  end
  deprecate :create!

  # Connects a tag instance to the specified asset
  def tag!(asset)
    raise StandardError, "Cannot tag an empty asset"   if asset.aliquots.empty?
    raise StandardError, "Cannot tag multiple samples" if asset.aliquots.size > 1
    asset.aliquots.first.update_attributes!(:tag => self)
  end

  # Map id is converted to a string here for consistency with elsewhere in the api.
  def summary
    {
      :tag_group => tag_group.name,
      :tag_index => map_id.to_s
    }
  end
end
