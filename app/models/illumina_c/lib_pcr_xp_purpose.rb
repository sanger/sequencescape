#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014 Genome Research Ltd.
class IlluminaC::LibPcrXpPurpose < PlatePurpose

  def transition_to(plate, state, contents = nil, customer_accepts_responsibility=false)
    super
    connect_requests(plate, state, contents)
  end


  def connect_requests(plate, state, contents = nil)
    return unless state == 'qc_complete'
    wells = plate.wells
    wells = wells.located_at(contents).include_stock_wells unless contents.blank?

    wells.each do |target_well|
      source_wells = target_well.stock_wells
      source_wells.each do |source_well|
        source_well.requests.detect {|r| r.is_a?(IlluminaC::Requests::LibraryRequest) }.tap do |upstream|
          next unless upstream.target_asset.nil?
          upstream.update_attributes!(:target_asset=> target_well)
          upstream.pass!
        end
      end
    end
  end

end
