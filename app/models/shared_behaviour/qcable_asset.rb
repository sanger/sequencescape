# frozen_string_literal: true
module SharedBehaviour
  # Include in classes which have an associated
  # qcable which handles their QC state.
  module QcableAsset
    def self.included(base)
      base.state_changer = StateChanger::QcableLabware
    end

    def state_of(plate)
      qcable_for(plate).state
    end

    private

    def qcable_for(plate)
      Qcable.find_by(asset_id: plate.id)
    end
  end
end
