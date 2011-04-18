class Io::Request < ::Core::Io::Base
  set_model_for_input(::Request)
  set_json_root(:request)
  set_eager_loading do |model|
    model.
      include_request_type.include_request_metadata.
      include_study.include_project.include_submission.
      include_source_asset.include_target_asset
  end

  define_attribute_and_json_mapping(%Q{
                               request_type.name  => type
    request_metadata.fragment_size_required_from  => fragment_size.from
      request_metadata.fragment_size_required_to  => fragment_size.to
                                           state <=> state

                                 submission.uuid  => submission.uuid
 
                                      study.name  => study.name
                                    project.name  => project.name
                     
                                           asset <=> source_asset

                         asset.sti_type.tableize  => source_asset.type
                                      asset.name  => source_asset.name

                               asset.sample.uuid  => source_asset.sample.uuid
                               asset.sample.name  => source_asset.sample.name
                   asset.sample.sanger_sample_id  => source_asset.sample.sanger_id
                            asset.sample.control  => source_asset.sample.control
        
                                    target_asset <=> target_asset

                  target_asset.sti_type.tableize  => target_asset.type
                               target_asset.name  => target_asset.name

                        target_asset.sample.uuid  => target_asset.sample.uuid
                        target_asset.sample.name  => target_asset.sample.name
            target_asset.sample.sanger_sample_id  => target_asset.sample.sanger_id
                     target_asset.sample.control  => target_asset.sample.control
  })
end
