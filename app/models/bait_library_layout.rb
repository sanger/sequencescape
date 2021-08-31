# frozen_string_literal: true
class BaitLibraryLayout < ApplicationRecord # rubocop:todo Style/Documentation
  include Uuid::Uuidable
  include ModelExtensions::BaitLibraryLayout

  # So we can track who is requesting the layout of the bait libraries
  belongs_to :user
  validates :user, presence: true

  # Bait libraries are laid out on a specific plate only once.
  belongs_to :plate
  validates :plate, presence: true
  validates :plate_id, uniqueness: true

  # The layout of the bait libraries is recorded so that we can see what happened.  It is serialized in a compact
  # form that maps the bait library to the wells it was put into, but can be accessed in the reverse.
  serialize :layout, Hash
  validates_unassigned :layout

  def well_layout
    {}.tap { |well_to_name| layout.map { |name, locations| locations.map { |l| well_to_name[l] = name } } }
  end

  # Records the assignment of the bait library to a particular well
  def record_bait_library_assignment(well, bait_library)
    # NOTE: The serialization of the hash prevents the use of a block
    # to set default values etc.
    (layout[bait_library.name] ||= []).push(well.map.description)
  end
  private :record_bait_library_assignment

  # Before creation the layout of the bait libraries on the plate must be performed, based on the information
  # specified as part of the submissions that lead to this plate.
  before_create :layout_bait_libraries_on_plate
  def layout_bait_libraries_on_plate
    # To improve the performance we store the aliquot IDs that need each of the individual bait libraries
    # attached to them in a hash.  Then we'll be able to bulk update them later.
    bait_libraries_to_aliquot_ids = Hash.new { |h, k| h[k] = [] }
    each_bait_library_assignment do |well, bait_library|
      bait_libraries_to_aliquot_ids[bait_library.id].concat(well.aliquot_ids)
      record_bait_library_assignment(well, bait_library)
    end

    # Bulk update the aliquots with the appropriate bait libraries
    bait_libraries_to_aliquot_ids.each do |bait_library_id, aliquot_ids|
      Aliquot.where(id: aliquot_ids).update_all(bait_library_id: bait_library_id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
  private :layout_bait_libraries_on_plate

  # rubocop:todo Metrics/MethodLength
  def each_bait_library_assignment # rubocop:todo Metrics/AbcSize
    plate.stock_wells.each do |well, stock_wells|
      bait_library =
        stock_wells
          .filter_map { |w| w.requests_as_source.for_submission_id(well.pool_id).first }
          .map(&:request_metadata)
          .map(&:bait_library)
          .uniq
      if bait_library.size > 1
        raise StandardError,
              "Multiple bait libraries found for #{well.map.description} on plate #{well.plate.human_barcode}"
      end

      yield(well, bait_library.first)
    end
  end

  # rubocop:enable Metrics/MethodLength
  private :each_bait_library_assignment

  # Generates the layout of bait libraries for preview.  In other words, none of the actually assignment is
  # done, just the recording, which would fail validation if an attempt was then made to save it.  So this is
  # safe to do.
  def generate_for_preview
    each_bait_library_assignment { |well, bait_library| record_bait_library_assignment(well, bait_library) }
  end
  private :generate_for_preview

  # This method can be used to view a previous of what will happen when the bait libraries are laid out
  # on a plate.
  def self.preview!(attributes = {}, &block)
    new(attributes, &block).tap do |layout|
      raise ActiveRecord::RecordInvalid, layout unless layout.valid?

      layout.unsaved_uuid!
      layout.send(:generate_for_preview)
    end
  end
end
