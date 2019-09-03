# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
# This class has been created as part of the {AssetRefactor} when not in
# refactor mode this class is pretty much ignored
class Labware < Asset
  include LabwareAssociations
  include Commentable
  include Uuid::Uuidable
  include AssetLink::Associations

  class_attribute :receptacle_class
  self.receptacle_class = 'Receptacle'
  self.sample_partial = 'assets/samples_partials/asset_samples'

  has_many :receptacles, dependent: :restrict_with_exception
  has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy
  has_many :aliquots, through: :receptacles
  has_many :samples, through: :receptacles
  has_many :studies, -> { distinct }, through: :receptacles
  has_many :projects, -> { distinct }, through: :receptacles
  has_many :requests_as_source, through: :receptacles
  has_many :requests_as_target, through: :receptacles
  has_many :transfer_requests_as_source, through: :receptacles
  has_many :transfer_requests_as_target, through: :receptacles
  has_many :submissions, through: :receptacles
  has_many :asset_groups, through: :receptacles
  belongs_to :purpose, foreign_key: :plate_purpose_id, optional: true, inverse_of: :labware
  has_one :spiked_in_buffer, through: :spiked_in_buffer_links, source: :ancestor
  has_one :spiked_in_buffer_links, -> { joins(:ancestor).where(labware: { sti_type: 'SpikedBuffer' }).direct },
          class_name: 'AssetLink', foreign_key: :descendant_id, inverse_of: :descendant

  scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }
  scope :for_search_query, lambda { |query|
    where('labware.name LIKE :name', name: "%#{query}%")
      .or(with_safe_id(query))
      .includes(:barcodes)
  }
  scope :for_lab_searches_display, -> { includes(:barcodes, requests_as_source: %i[pipeline batch]).order('requests.pipeline_id ASC') }
  scope :named, ->(name) { where(name: name) }

  def human_barcode
    'UNKNOWN'
  end

  # Assigns name
  # @note Overridden on subclasses to append the asset id to the name
  #       via on_create callbacks
  def generate_name(new_name)
    self.name = new_name
  end

  def display_name
    name.presence || "#{sti_type} #{id}"
  end
end
