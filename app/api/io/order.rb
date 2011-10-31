class ::Io::Order < ::Core::Io::Base
  REQUEST_OPTIONS_FIELDS = Hash[{
    :read_length                 => 'read_length',
    :library_type                => 'library_type',
    :fragment_size_required_from => 'fragment_size_required.from',
    :fragment_size_required_to   => 'fragment_size_required.to'
  }.map { |k,v| [ k, "request_options.#{v}"] }]

  def self.json_field_for(attribute)
    REQUEST_OPTIONS_FIELDS[attribute.to_sym] || super
  end

  set_model_for_input(::Order)
  set_json_root(:order)
  set_eager_loading { |model| model.include_study.include_project.include_assets }
  
  define_attribute_and_json_mapping(%Q{
                                          study <=  study
                                     study.name  => study.name

                                        project <=  project
                                   project.name  => project.name
       
                                    asset_group <=  asset_group
                               asset_group_name <=  asset_group_name

                                         assets <=> assets

                     order.request_type_objects  => request_types
               order.request_options_structured <=> request_options
  })
end
