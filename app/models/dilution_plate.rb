# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class DilutionPlate < Plate
  has_many :pico_descendants, ->() { where(sti_type: [PicoAssayPlate, PicoAssayAPlate, PicoAssayBPlate].map(&:name)) },
    through: :links_as_ancestor, source: :descendant

  # We have to put the asset_links.direct condition on here, rather than go through :links_as_parent as it seems that
  # rails doesn't cope with conditions on has_many_through relationships where the relationship itself also have conditions
  scope :with_pico_children,  -> {
    joins(:pico_descendants)
      .select('`assets`.*')
      .where(asset_links: { direct: true })
      .uniq
  }

  def pico_children
    pico_descendants.where(['asset_links.direct = ?', true])
  end

  def to_pico_hash
    { pico_dilution: {
        child_barcodes: pico_children.map { |plate| plate.barcode_dilution_factor_created_at_hash }
      }.merge(barcode_dilution_factor_created_at_hash),
      study_name: study_name
    }
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
