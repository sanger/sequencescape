#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class ProductCriteria < ActiveRecord::Base

  set_table_name('product_criteria')

  belongs_to :product
  validates_presence_of :product, :stage, :behaviour

  validates_uniqueness_of :stage, :scope => [:product_id,:deprecated_at]
  validate :behaviour_exists?, :if => :behaviour?

  serialize :configuration

  include SharedBehaviour::Indestructable
  include SharedBehaviour::Deprecatable
  include SharedBehaviour::Immutable


  def assess(asset)
    ProductCriteria.const_get(behaviour).new(configuration,asset)
  end

  private

  def behaviour_exists?
    # We can't use const_defined? here as it doesn't trigger rails autoloading.
    # We could probably use the autoloading API more directly, but it doesn't
    # seem to be intended to be used outside of Rails itself.
    ProductCriteria.const_get(behaviour)
    true
  rescue NameError
    errors.add(:behaviour,"#{behaviour} is not recognized")
    false
  end
end
