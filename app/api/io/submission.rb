class ::Io::Submission < ::Core::Io::Base
  REQUEST_OPTIONS_FIELDS = Hash[{
    :read_length                 => 'read_length',
    :library_type                => 'library_type',
    :fragment_size_required_from => 'fragment_size_required.from',
    :fragment_size_required_to   => 'fragment_size_required.to',
    :bait_library_name           => 'bait_library'
  }.map { |k,v| [ k, "request_options.#{v}"] }]

  def self.json_field_for(attribute)
    REQUEST_OPTIONS_FIELDS[attribute.to_sym] || super
  end

  set_model_for_input(::Submission)
  set_json_root(:submission)
  set_eager_loading { |model| model.include_order }
  
  define_attribute_and_json_mapping(%Q{
                                          state  => state

                                    order.study <=  study
                               order.study.name  => study.name

                                  order.project <=  project
                             order.project.name  => project.name
       
                              order.asset_group <=  asset_group
                         order.asset_group_name <=  asset_group_name

                                   order.assets <=> assets

                     order.request_type_objects  => request_types
               order.request_options_structured <=> request_options
  })

  def self.json_field_for(attribute)
    super.sub(/^order\./, '')
  end
end
