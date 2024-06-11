# frozen_string_literal: true
##
# StripTubes can be thought of as long skinny plates.
# Unlike normal plates they can be kept in a rack.
# Strip tubes don't get a barcode assigned upfront.
class StripTube < Plate
  has_many :submissions, through: :well_requests_as_target

  def friendly_name
    name
  end

  def subject_type
    'strip_tube'
  end

  def library_source_plates
    source_plates
  end

  # Until we know how barcodes are going to work, we'll just override this
  def self.create_with_barcode!(*args, &)
    attributes = args.extract_options!
    attributes.delete(:barcode)
    attributes.delete(:sanger_barcode)
    create!(attributes, &)
  end
end
