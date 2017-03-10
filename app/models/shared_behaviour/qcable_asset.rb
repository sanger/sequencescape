module SharedBehaviour
  # Include in classes which have an associated
  # qcable which handles their QC state.
  module QcableAsset
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
end
