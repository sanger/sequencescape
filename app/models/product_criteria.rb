# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

class ProductCriteria < ApplicationRecord
  STAGE_STOCK = 'stock'

  # By default rails will try and name the table 'product_criterias'
  # We don't use the singular 'ProductCriterion' as the class name
  # as a single record may define multiple criteria.
  self.table_name = ('product_criteria')

  include HasBehaviour
  has_behaviour Advanced, behaviour_name: 'Advanced'
  has_behaviour Basic, behaviour_name: 'Basic'

  belongs_to :product
  validates_presence_of :product, :stage, :behaviour

  validates_uniqueness_of :stage, scope: [:product_id, :deprecated_at]
  validates :behaviour, inclusion: { in: registered_behaviours }

  serialize :configuration

  scope :for_stage, ->(stage) { where(stage: stage) }
  scope :stock, ->()          { where(stage: STAGE_STOCK) }
  scope :older_than, ->(id)   { where(['id < ?', id]) }

  before_create :set_version_number

  include SharedBehaviour::Indestructable
  include SharedBehaviour::Deprecatable
  include SharedBehaviour::Immutable

  def target_plate_purposes
    configuration.fetch('target_plate_purposes', nil)
  end

  def assess(asset, target_wells = nil)
    self.class.with_behaviour(behaviour).new(configuration, asset, target_wells)
  end

  def headers
    self.class.with_behaviour(behaviour).headers(configuration)
  end

  private

  def set_version_number
    v = product.product_criteria.for_stage(stage).count + 1
    self.version = v
  end
end
