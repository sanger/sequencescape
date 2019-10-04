module Io
  # Controls API V1 IO for {::TransferRequest}
  class TransferRequest < ::Core::Io::Base
    set_model_for_input(::TransferRequest)
    set_json_root(:transfer_request)
    set_eager_loading do |model|
      model
        .includes(asset: :uuid_object)
        .includes(target_asset: :uuid_object)
    end

    define_attribute_and_json_mapping("
      state <=> state

      submission.uuid  => submission.uuid
      submission <= submission
      asset <=  source_asset
      target_asset <=  target_asset
    ")
  end
end
