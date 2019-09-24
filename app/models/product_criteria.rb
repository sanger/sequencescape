class ProductCriteria < ApplicationRecord
  STAGE_STOCK = 'stock'.freeze

  # By default rails will try and name the table 'product_criterias'
  # We don't use the singular 'ProductCriterion' as the class name
  # as a single record may define multiple criteria.
  self.table_name = ('product_criteria')

  include HasBehaviour
  has_behaviour Advanced, behaviour_name: 'Advanced'
  has_behaviour Basic, behaviour_name: 'Basic'

  belongs_to :product
  validates :product, :stage, :behaviour, presence: true

  validates :stage, uniqueness: { scope: %i[product_id deprecated_at], case_sensitive: false }
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
