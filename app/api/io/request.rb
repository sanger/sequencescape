# frozen_string_literal: true
# Controls API V1 IO for Request
class Io::Request < Core::Io::Base
  set_model_for_input(::Request)
  set_json_root(:request)
  set_eager_loading do |model|
    model.include_request_type.include_request_metadata.include_submission.include_source_asset.include_target_asset
  end

  define_attribute_and_json_mapping(
    '
                               request_type.name  => type
    request_metadata.fragment_size_required_from  => fragment_size.from
      request_metadata.fragment_size_required_to  => fragment_size.to
                                           state <=> state

                                 submission.uuid  => submission.uuid

                                           asset <=  source_asset
                            asset.api_asset_type  => source_asset.type
                                      asset.name  => source_asset.name
                                  asset.aliquots  => source_asset.aliquots

                                    target_asset <=  target_asset
                     target_asset.api_asset_type  => target_asset.type
                               target_asset.name  => target_asset.name
                           target_asset.aliquots  => target_asset.aliquots
  '
  )
end
