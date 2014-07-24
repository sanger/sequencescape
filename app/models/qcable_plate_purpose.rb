class QcablePlatePurpose < PlatePurpose

  module ClassBehaviour

    def state_of(plate)
      qcable_for(plate).state
    end

    def transition_to(plate, state, _=nil)
      qcable_for(plate).transition_to(state)
    end

    private

    def qcable_for(plate)
      Qcable.find_by_asset_id(plate.id)
    end
  end

  include ClassBehaviour

end
