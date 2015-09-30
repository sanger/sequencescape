#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class Product < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :deprecated_at
  before_destroy :prevent_destruction
  has_many :submission_templates, :inverse_of => :product

  named_scope :active, :conditions => { :deprecated_at => nil }

  def deprecate!
    self.deprecated_at = DateTime.now
    save!
  end

  # If we have a datestamp we are deprecated
  def deprecated?
    deprecated_at?
  end

  private

  def prevent_destruction
    errors.add(:base,'can not be destroyed and should be deprecated instead!')
    raise ActiveRecord::RecordNotDestroyed, self
    false
  end
end
