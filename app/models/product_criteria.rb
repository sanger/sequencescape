#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class ProductCriteria < ActiveRecord::Base

  STAGE_STOCK = 'stock'


  # By default rails will try and name the table 'product_criterias'
  # We don't use the singular 'ProductCriterion' as the class name
  # as a single record may define multiple criteria.
  set_table_name('product_criteria')

  belongs_to :product
  validates_presence_of :product, :stage, :behaviour

  validates_uniqueness_of :stage, :scope => [:product_id,:deprecated_at]
  validate :behaviour_exists?, :if => :behaviour?

  serialize :configuration

  named_scope :for_stage, lambda {|stage| {:conditions=>{:stage=>stage} } }
  named_scope :stock, {:conditions=>{:stage=>STAGE_STOCK}}
  named_scope :older_than, lambda {|id| { :conditions => ['id < ?',id] } }

  before_create :set_version_number

  include SharedBehaviour::Indestructable
  include SharedBehaviour::Deprecatable
  include SharedBehaviour::Immutable


  def assess(asset)
    ProductCriteria.const_get(behaviour).new(configuration,asset)
  end

  def headers
    ProductCriteria.const_get(behaviour).headers(configuration)
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

  def set_version_number
    v = product.product_criteria.for_stage(stage).count + 1
    self.version = v
  end
end
