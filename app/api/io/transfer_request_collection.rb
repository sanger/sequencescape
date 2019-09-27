module Io
  # Controls API V1 IO for {::TransferRequestCollection}
  class TransferRequestCollection < ::Core::Io::Base
    set_model_for_input(::TransferRequestCollection)
    set_json_root(:transfer_request_collection)

    set_eager_loading do |model|
      # Note we use preload here, rather than includes, as otherwise the target_tubes nuke our loaded transfer requests
      model
        .eager_load(user: :uuid_object)
        .preload(target_tubes: [:uuid_object, :purpose, { aliquots: Io::Aliquot::PRELOADS }, :transfer_requests_as_target])
        .preload(transfer_requests: [:uuid_object, { asset: :uuid_object, target_asset: :uuid_object, submission: :uuid_object }])
    end

    define_attribute_and_json_mapping("
      user <= user
      transfer_requests => transfer_requests
      transfer_requests_io <= transfer_requests
      target_tubes => target_tubes
    ")
  end
end
