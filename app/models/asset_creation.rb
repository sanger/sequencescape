# frozen_string_literal: true
# Factory class primarily used by the API to generate new
# pieces of {Asset labware}. In addition provides an audit trail to record who
# created the Asset.
class AssetCreation < ApplicationRecord
  class ParentAssociation < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = ('asset_creation_parents')
    belongs_to :asset_creation
    belongs_to :parent, class_name: 'Labware'
  end

  include Uuid::Uuidable
  include Asset::Ownership::ChangesOwner
  extend ModelExtensions::Plate::NamedScopeHelpers

  belongs_to :user

  validates :parent, presence: true

  delegate :nil?, to: :parent, prefix: true
  private :parent_nil?

  belongs_to :child_purpose, class_name: 'Purpose'
  validates :child_purpose, presence: true, unless: :multiple_purposes

  before_create :process_children
  def process_children
    create_children!
    connect_parent_and_children
    record_creation_of_children
  end
  private :process_children

  def create_ancestor_asset!(asset, child)
    AssetLink.create_edge!(asset, child)
  end

  def connect_parent_and_children
    children.each { |child| create_ancestor_asset!(parent, child) }
  end
  private :connect_parent_and_children

  def multiple_purposes
    false
  end
end
