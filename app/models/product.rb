# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

class Product < ActiveRecord::Base
  include SharedBehaviour::Indestructable
  include SharedBehaviour::Deprecatable

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :deprecated_at
  has_many :product_product_catalogues, dependent: :destroy
  has_many :product_catalogues, through: :product_product_catalogues
  has_many :submission_templates, inverse_of: :product, through: :product_catalogues
  has_many :orders
  has_many :product_criteria, inverse_of: :product, class_name: 'ProductCriteria'

  scope :with_stock_report, ->() {
    joins(:product_criteria)
      .where(product_criteria: { deprecated_at: nil, stage: ProductCriteria::STAGE_STOCK })
  }

  scope :alphabetical, ->() { order(:name) }

  def stock_criteria
    product_criteria.active.stock.first
  end

  def display_name
    deprecated? ? "#{name} (Deprecated #{deprecated_at.to_formatted_s(:iso8601)})" : name
  end
end
