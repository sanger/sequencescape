module Api
  module V2
    module Aker
      class ProcessResource < JSONAPI::Resource
        model_name 'Aker::Process'

        attributes :name, :tat

        has_many :process_module_pairings, class_name: 'ProcessModulePairing', foreign_key: :aker_process_id, always_include_linkage_data: true
      end
    end
  end
end
