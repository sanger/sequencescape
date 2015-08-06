#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.
class DilutionPlate < Plate

  # We have to put the asset_links.direct condition on here, rather than go through :links_as_parent as it seems that
  # rails doesn't cope with conditions on has_many_through relationships where the relationship itself also have conditions
  named_scope :with_pico_children, { :joins => :pico_descendants, :select=>'DISTINCT `assets`.*', :conditions=>['asset_links.direct = ?',true] }

  has_many :pico_descendants,
    :through => :links_as_ancestor,
    :conditions => { :sti_type=>[PicoAssayPlate,PicoAssayAPlate,PicoAssayBPlate].map(&:name) },
    :source => :descendant

  def pico_children
    pico_descendants.find(:all,:conditions=>['asset_links.direct = ?',true])
  end

  def to_pico_hash
    {:pico_dilution => {
        :child_barcodes => pico_children.map{ |plate| plate.barcode_dilution_factor_created_at_hash }
      }.merge(barcode_dilution_factor_created_at_hash),
        :study_name => study_name
    }
  end

  def study_name
    study.try(:name) || ""
  end

end
