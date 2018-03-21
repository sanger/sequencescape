# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class DilutionPlate < Plate
  PICO_TYPES = [PicoAssayPlate, PicoAssayAPlate, PicoAssayBPlate].map(&:name)

  has_many :pico_descendants, ->() { where(sti_type: PICO_TYPES) }, through: :links_as_ancestor, source: :descendant, class_name: 'PicoAssayPlate'
  has_many :pico_children,    ->() { where(sti_type: PICO_TYPES) }, through: :links_as_parent,   source: :descendant, class_name: 'PicoAssayPlate'

  # Note: joins here fails as it doesn't populate the associations
  # includes ends up generating invalid sql, as rails doesn't seem to know how to apply conditions to a has_many through
  # Eager load works just fine however. This effectively uses the join SQL, but populates the association
  scope :with_pico_children,  -> {
    eager_load(pico_children: [:barcode_prefix, :plate_metadata])
      .where.not(pico_children_assets: { id: nil })
  }

  scope :for_pico_view, -> {
    preload(:barcode_prefix, :plate_metadata)
  }

  def to_pico_hash
    { pico_dilution: {
      child_barcodes: pico_children.map { |plate| plate.barcode_dilution_factor_created_at_hash }
    }.merge(barcode_dilution_factor_created_at_hash),
      study_name: study_name }
  end

  private

  def study_name
    names = studies.pluck(:name)
    if names.length <= 1
      names.first
    else
      "#{names.first} (#{names.length - 1} others)"
    end
  end
end
