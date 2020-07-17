# frozen_string_literal: true

# Sequenom was a geneotyping process in which four 96 well parent plates were
# transferred onto a single 384 well plate prior to genotyping.
# The four plates were interlaced such that:
# A1: Plate 1, well A1
# A2: Plate 2, well A1
# B1: Plate 3, well A1
# B2: Plate 4, well A1
# The remaining methods allow legacy Sequenom plates to get viewed.
class SequenomQcPlate < Plate
  self.per_page = 50
  self.default_plate_size = 384

  attr_accessor :gender_check_bypass, :plate_prefix, :user_barcode

  validates :name, presence: true

  def self.default_purpose
    PlatePurpose.create_with(size: default_plate_size).find_or_create_by!(name: 'Sequenom')
  end

  def source_plates
    return [] if parents.empty?

    source_barcodes.map do |plate_barcode|
      if plate_barcode.blank?
        nil
      else
        parents.detect { |plate| plate.barcode_number == plate_barcode }
      end
    end
  end

  protected

  def source_barcodes
    [label_match[2], label_match[3], label_match[4], label_match[5]]
  end

  # Create a match object for the input plate names from this
  # sequenom plate's name.
  def label_match
    @label_match ||= name.match(/^([^\d]+)(\d+)?_(\d+)?_(\d+)?_(\d+)?_(\d+)$/)
  end
end
