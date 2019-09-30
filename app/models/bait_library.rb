# frozen_string_literal: true

# A bait library is used in the sequence capture process (eg. ISC)
# to enrich for DNA regions matching the library.
# This allows for greater coverage of coding sequences, or
# the separation of DNA by species.
class BaitLibrary < ApplicationRecord
  include SharedBehaviour::Named

  module Associations
    def self.included(base)
      base.class_eval do
        belongs_to :bait_library
      end
    end
  end

  # The company or individual who supplies the {BaitLibrary}
  class Supplier < ApplicationRecord
    self.table_name = ('bait_library_suppliers')

    # The names of suppliers needs to be unique
    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :visible, -> { where(visible: true) }

    # They supply many bait libraries
    has_many :bait_libraries, foreign_key: :bait_library_supplier_id

    def hide
      self.visible = false
      save!
    end
  end

  # All bait libraries belong to a supplier
  belongs_to :bait_library_supplier, class_name: 'BaitLibrary::Supplier'
  validates :bait_library_supplier, presence: true

  # Within a supplier we have a unique identifier for each bait library.  Custom bait libraries
  # do not have this identifier, so nil is permitted.
  validates :supplier_identifier, uniqueness: { scope: :bait_library_supplier_id, allow_nil: true, case_sensitive: false }
  before_validation :blank_as_nil

  # The names of the bait library are considered unique within the supplier
  validates :name, presence: true, uniqueness: { scope: :bait_library_supplier_id, case_sensitive: false }

  # All bait libraries target a specific species and cannot be mixed
  validates :target_species, presence: true

  # All bait libraries have a bait library type
  belongs_to :bait_library_type

  scope :visible, -> { where(visible: true) }

  delegate :category, to: :bait_library_type

  def hide
    self.visible = false
    save!
  end

  private

  def blank_as_nil
    self.supplier_identifier = nil if supplier_identifier.blank?
  end
end
