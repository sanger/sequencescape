# Controls API V1 IO for {::Order}
class ::Io::Order < ::Core::Io::Base
  REQUEST_OPTIONS_FIELDS = Hash[{
    read_length: 'read_length',
    library_type: 'library_type',
    fragment_size_required_from: 'fragment_size_required.from',
    fragment_size_required_to: 'fragment_size_required.to',
    pcr_cycles: 'pcr_cycles'
  }.map { |k, v| ["request_options.#{k}".to_sym, "request_options.#{v}"] }]

  def self.json_field_for(attribute)
    REQUEST_OPTIONS_FIELDS[attribute.to_sym] || super
  end

  set_model_for_input(::Order)
  set_json_root(:order)
  set_eager_loading { |model| model.include_study.include_project.include_assets }

  define_attribute_and_json_mapping("
                                          study <=  study
                                     study.name  => study.name

                                        project <=  project
                                   project.name  => project.name

                                    asset_group <=  asset_group
                               asset_group_name <=  asset_group_name

                                         assets <=> assets

                           request_type_objects  => request_types
                     request_options_structured <=> request_options

                                           user <=  user
  ")
end
