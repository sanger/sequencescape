# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class QcablePlatePurpose < PlatePurpose
  module ClassBehaviour
    def state_of(plate)
      qcable_for(plate).state
    end

    def transition_to(plate, state, *_ignored)
      qcable_for(plate).transition_to(state)
    end

    private

    def qcable_for(plate)
      Qcable.find_by(asset_id: plate.id)
    end
  end

  include ClassBehaviour
end
