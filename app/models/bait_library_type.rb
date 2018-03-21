# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class BaitLibraryType < ApplicationRecord
  include SharedBehaviour::Named

  # category is used for billing, to differentiate between products with Custom and Standard bait libraries
  enum category: [:standard, :custom]

  has_many :bait_libraries

  # Types have names, need to be unique
  validates_presence_of :name, :category
  validates_uniqueness_of :name

  scope :visible, -> { where(visible: true) }

  def hide
    self.visible = false
    save!
  end
end
