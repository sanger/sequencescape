module Api
  module V2
    module Aker
      class ProcessModulePairingResource < JSONAPI::Resource
        model_name 'Aker::ProcessModulePairing'

        attributes :default_path, :from_step, :to_step

        def from_step
          @model.from_step.name
        end

        def to_step
          @model.to_step.name
        end
      end
    end
  end
end
