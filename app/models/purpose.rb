# The Purpose of a piece of {Labware} describes its role in the lab. While
# most labware will retain a single purpose through their life cycle, it is
# possible for purpose to be changed. Ideally this should be performed with
# a {PlateConversion} to ensure proper tracking.
#
# Historically Purpose has modified the behaviour of its corresponding
# {Labware}, with a number of methods, such as {Plate#state} delegating
# to {Plate#plate_purpose}. While this is still occasionally required, it tends
# to result in quite brittle, unflexible behaviour. More recently we have
# been trying to push these differences in business logic outwards. In this new
# approach the Pipeline handles differences in behaviour, and the purpose acts
# merely as a tag, which can be used to inform the pipeline how it may wish to
# proceed. This approach makes {Labware} far more interchangeable.
#
# Information about which purpose classes are used, and their last activity
# can be generated by running: `bundle exec rake report:purposes`
# in the appropriate environment. (Probably production)
#
# @note Purpose was originally just a property of {Plate plates} and
#       so was originally just {PlatePurpose}. As a result its table,
#       and the foreign key on labware are plate_purposes and plate_purpose_id
#       despite the fact they can now be applied to {Tube tubes} as well.
#
# @abstract Probably best to avoid using directly.
class Purpose < ApplicationRecord
  include Relationship::Associations
  include Uuid::Uuidable

  self.table_name = 'plate_purposes'

  class_attribute :default_prefix
  class_attribute :state_changer

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type
  belongs_to :source_purpose, class_name: 'Purpose'
  belongs_to :barcode_prefix, optional: false
  # Things that are created are often in a default location!
  has_many :messenger_creators, inverse_of: :purpose
  has_many :labware, inverse_of: :purpose

  before_validation :set_default_barcode_prefix

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :name, format: { with: /\A\w[\s\w.\-]+\w\z/i }, presence: true, uniqueness: { case_sensitive: false }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  # NOTE: We should validate against valid asset subclasses, but running into some issues with
  # subclass loading while seeding.
  validates :target_type, presence: true

  delegate :prefix, to: :barcode_prefix, allow_nil: true

  def source_plate(labware)
    # Stock_plate is deprecated, but we still have some tubes with special behaviour
    # We'll allow its usage here to support existing code.
    ActiveSupport::Deprecation.silence do
      # Rails 6 lets us do this:
      # ActiveSupport::Deprecation.allow(:stock_plate) do
      source_purpose_id.present? ? labware.ancestor_of_purpose(source_purpose_id) : labware.stock_plate
    end
  end

  def source_plates(labware)
    # Stock_plate is deprecated, but we still have some tubes with special behaviour
    # We'll allow its usage here
    ActiveSupport::Deprecation.silence do
      # Rails 6 lets us do this:
      # ActiveSupport::Deprecation.allow(:stock_plate) do
      source_purpose_id.present? ? labware.ancestors_of_purpose(source_purpose_id) : [labware.stock_plate].compact
    end
  end

  def source_purpose_name=(source_purpose_name)
    self.source_purpose = Purpose.find_by!(name: source_purpose_name)
  end

  def barcode_type
    barcode_printer_type&.printer_type_id
  end

  def target_class
    target_type.constantize
  end

  def prefix=(prefix)
    self.barcode_prefix = BarcodePrefix.find_or_create_by(prefix: prefix)
  end

  def set_default_barcode_prefix
    self.prefix ||= default_prefix
  end
end

require_dependency 'tube/purpose'
require_dependency 'plate_purpose'
require_dependency 'tube_rack/purpose'
