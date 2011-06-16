class BaitLibraryLayout < ActiveRecord::Base
  include Transfer::WellHelpers

  # So we can track who is requesting the layout of the bait libraries
  belongs_to :user

  # Bait libraries are laid out on a specific plate only once.
  belongs_to :plate
  validates_presence_of :plate
  validates_uniqueness_of :plate_id

  # The layout of the bait libraries is recorded so that we can see what happened
  serialize :layout
  validates_unassigned :layout

  # Records the assignment of the bait library to a particular well
  def record_bait_library_assignment(well, bait_library)
    self.layout ||= {}
    self.layout[well.map.description] = bait_library.name
  end
  private :record_bait_library_assignment

  # Before creation the layout of the bait libraries on the plate must be performed, based on the information
  # specified as part of the submissions that lead to this plate.
  before_create :layout_bait_libraries_on_plate
  def layout_bait_libraries_on_plate
    each_bait_library_assignment do |well, bait_library|
      well.aliquots.each { |aliquot| aliquot.update_attributes!(:bait_library => bait_library) }
      record_bait_library_assignment(well, bait_library)
    end
  end
  private :layout_bait_libraries_on_plate

  def each_bait_library_assignment(&block)
    plate.wells.walk_in_column_major_order do |well, _|
      stock_well   = locate_stock_well_for(well)
      bait_library = stock_well.requests.detect { |r| r.submission_id.present? }.try(:request_metadata).try(:bait_library)
      yield(well, bait_library)
    end
  end
  private :each_bait_library_assignment

  # Generates the layout of bait libraries for preview.  In other words, none of the actually assignment is
  # done, just the recording, which would fail validation if an attempt was then made to save it.  So this is
  # safe to do.
  def generate_for_preview
    each_bait_library_assignment do |well, bait_library|
      record_bait_library_assignment(well, bait_library)
    end
  end
  private :generate_for_preview

  # This method can be used to view a previous of what will happen when the bait libraries are laid out
  # on a plate.
  def self.preview!(attributes = {}, &block)
    new(attributes, &block).tap do |layout|
      raise ActiveRecord::RecordInvalid, layout unless layout.valid?
      layout.send(:generate_for_preview)
    end
  end
end
