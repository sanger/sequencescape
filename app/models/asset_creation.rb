class AssetCreation < ActiveRecord::Base
  include Uuid::Uuidable
  include Asset::Ownership::ChangesOwner
  extend ModelExtensions::Plate::NamedScopeHelpers

  include_plate_named_scope :parent

  belongs_to :user
  validates_presence_of :user

  belongs_to :parent, :class_name => 'Plate'
  validates_presence_of :parent

  def parent_nil?
    parent.nil?
  end
  private :parent_nil?

  belongs_to :child_purpose, :class_name => 'Purpose'
  validates_presence_of :child_purpose
  validates_each(:child_purpose, :unless => :parent_nil?, :allow_blank => true) do |record, attr, child_purpose|
    record.errors.add(:child_purpose, 'is not a valid child type') unless record.parent.purpose.child_purposes.include?(child_purpose)
  end

  before_create :process_children
  def process_children
    create_children!
    connect_parent_and_children
    connect_children_to_parent_study
    record_creation_of_children
  end
  private :process_children

  def connect_parent_and_children
    children.each { |child| AssetLink.create_edge!(parent, child) }
  end
  private :connect_parent_and_children

  def connect_children_to_parent_study
    RequestFactory.create_assets_requests(children.map(&:id), parent.study.id) if parent.study.present?
  end
  private :connect_children_to_parent_study
end
