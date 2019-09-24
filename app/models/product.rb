class Product < ApplicationRecord
  include SharedBehaviour::Indestructable
  include SharedBehaviour::Deprecatable

  validates :name, presence: true
  validates :name, uniqueness: { scope: :deprecated_at, case_sensitive: false }
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
