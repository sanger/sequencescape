# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class QcableLibraryPlatePurpose < PlatePurpose
  module ClassBehaviour
    def state_of(plate)
      qcable_for(plate).state
    end

    def transition_to(plate, _state, *_ignored)
      assign_library_information_to_wells(plate)
    end

    private

    def qcable_for(plate)
      Qcable.find_by(asset_id: plate.id)
    end

    # Ensure that the library information within the aliquots of the well is correct.
    def assign_library_information_to_wells(plate)
      plate.wells.each do |well|
        library_type, insert_size = 'QA1', Aliquot::InsertSize.new(100, 100)

        well.aliquots.each do |aliquot|
          aliquot.library      ||= well
          aliquot.library_type ||= library_type
          aliquot.insert_size  ||= insert_size
          aliquot.save!
        end
      end
    end
  end

  include ClassBehaviour
end
