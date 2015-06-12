module PrunedJsonSerialization
  def self.included(base)
    base.instance_eval do |klass|
      def self.build_from_pruned_json(json)
        obj = PrunedJsonSerialization::transcode_from_object(JSON.parse(json))
        if obj.kind_of?(Array)
          obj.each {|o| o.save!}
        else
          obj.save!
        end
      end
    end
  end



  def render_to_pruned_json
    attribute_hash(self).to_json
  end

  def transcode_to_object_and_prune(obj, prune_list, level=0)
    obj = transcode_to_object(obj,level,20)
    if obj.kind_of? Array
      obj.map{|n| PrunedJsonSerialization::prune_attributes(n, prune_list)}
    else
      PrunedJsonSerialization::prune_attributes(obj, prune_list)
    end
  end

  def self.prune_attributes(obj, attributes_list=nil)
    unless obj.nil? ||  attributes_list.nil?
      attributes_list.each do |s|
        obj.delete(s.to_s)
        obj.delete(s)
      end
    end
    obj
  end

  def json2
    "[
   {
      \"transcoded_class\":\"RequestType::Validator\",
      \"request_option\":\"library_type\",
      \"request_type\":{
         \"transcoded_class\":\"RequestType\",
         \"transcoded_find_by_key\":\"library_creation\",
         \"transcoded_key\":\"id\"
      },
      \"valid_options\":{
         \"transcoded_class\":\"RequestType::Validator::LibraryTypeValidator\",
         \"request_type\":{
            \"transcoded_class\":\"RequestType\",
            \"transcoded_find_by_key\":\"library_creation\",
            \"transcoded_key\":\"id\"
         }
      }
   },
   {
      \"transcoded_class\":\"RequestType::Validator\",
      \"request_option\":\"library_type\",
      \"request_type\":{
         \"transcoded_class\":\"RequestType\",
         \"transcoded_find_by_key\":\"illumina_c_library_creation\",
         \"transcoded_key\":\"id\"
      },
      \"valid_options\":{
         \"transcoded_class\":\"RequestType::Validator::LibraryTypeValidator\",
         \"request_type\":{
            \"transcoded_class\":\"RequestType\",
            \"transcoded_find_by_key\":\"illumina_c_library_creation\",
            \"transcoded_key\":\"id\"
         }
      }
   }
]"
  end

  def json
    "{
       \"transcoded_class\":\"LibraryCreationPipeline\",
       \"active\":true,
       \"asset_type\":\"LibraryTube\",
       \"automated\":false,
       \"control_request_type\":{
          \"transcoded_class\":\"RequestType\",
          \"transcoded_find_by_key\":\"illumina_c_library_creation_control\"
       },
       \"externally_managed\":false,
       \"group_by_parent\":null,
       \"group_by_study_to_delete\":true,
       \"group_by_submission_to_delete\":null,
       \"group_name\":null,
       \"location\":{
          \"transcoded_class\":\"Location\",
          \"transcoded_find_by_name\":\"Library creation freezer\"
       },
       \"max_number_of_groups\":null,
       \"max_size\":null,
       \"min_size\":null,
       \"multiplexed\":null,
       \"name\":\"Illumina-C Library preparation 3\",
       \"next_pipeline\":null,
       \"paginate\":false,
       \"previous_pipeline\":null,
       \"sorter\":0,
       \"sti_type\":\"LibraryCreationPipeline\",
       \"summary\":true,
       \"workflow\":{
          \"transcoded_class\":\"LabInterface::Workflow\",
          \"item_limit\":null,
          \"locale\":\"External\",
          \"name\":\"Library preparation 3\",
          \"tasks\":[
             {
                \"transcoded_class\":\"SetDescriptorsTask\",
                \"batched\":null,
                \"interactive\":null,
                \"lab_activity\":true,
                \"location\":null,
                \"name\":\"Initial QC\",
                \"per_item\":null,
                \"sorted\":1,
                \"sti_type\":\"SetDescriptorsTask\"
             },
             {
                \"transcoded_class\":\"SetDescriptorsTask\",
                \"batched\":null,
                \"interactive\":false,
                \"lab_activity\":true,
                \"location\":null,
                \"name\":\"Gel\",
                \"per_item\":false,
                \"sorted\":2,
                \"sti_type\":\"SetDescriptorsTask\"
             },
             {
                \"transcoded_class\":\"SetDescriptorsTask\",
                \"batched\":true,
                \"interactive\":false,
                \"lab_activity\":true,
                \"location\":null,
                \"name\":\"Characterisation\",
                \"per_item\":false,
                \"sorted\":3,
                \"sti_type\":\"SetDescriptorsTask\"
             }
          ]
       },
       \"request_types\":[
          {
             \"transcoded_class\":\"RequestType\",
             \"asset_type\":\"SampleTube\",
             \"billable\":true,
             \"deprecated\":true,
             \"for_multiplexing\":false,
             \"initial_state\":\"pending\",
             \"key\":\"library_creation_3\",
             \"morphology\":0,
             \"multiples_allowed\":false,
             \"name\":\"Library creation 3\",
             \"no_target_asset\":false,
             \"order\":1,
             \"pooling_method\":null,
             \"product_line\":null,
             \"request_class_name\":\"LibraryCreationRequest\",
             \"request_parameters\":null,
             \"target_asset_type\":null,
             \"target_purpose\":null,
             \"workflow\":{
                \"transcoded_class\":\"Submission::Workflow\",
                \"transcoded_find_by_key\":\"short_read_sequencing\"
             }
          },
          {
             \"transcoded_class\":\"RequestType\",
             \"asset_type\":\"SampleTube\",
             \"billable\":true,
             \"deprecated\":false,
             \"for_multiplexing\":false,
             \"initial_state\":\"pending\",
             \"key\":\"illumina_c_library_creation_3\",
             \"morphology\":0,
             \"multiples_allowed\":false,
             \"name\":\"Illumina-C Library creation 3\",
             \"no_target_asset\":false,
             \"order\":1,
             \"pooling_method\":null,
             \"product_line\":{
                \"transcoded_class\":\"ProductLine\",
                \"transcoded_find_by_name\":\"Illumina-C\"
             },
             \"request_class_name\":\"LibraryCreationRequest\",
             \"request_parameters\":null,
             \"target_asset_type\":null,
             \"target_purpose\":null,
             \"workflow\":{
                \"transcoded_class\":\"Submission::Workflow\",
                \"transcoded_find_by_key\":\"short_read_sequencing\"
             }
          }
       ]
    }"
  end

  def json3
"{
   \"transcoded_class\":\"LibraryCreationPipeline\",
   \"active\":true,
   \"asset_type\":\"LibraryTube\",
   \"automated\":false,
   \"control_request_type\":{
      \"transcoded_class\":\"RequestType\",
      \"transcoded_find_by_key\":\"illumina_c_library_creation_control\",
      \"transcoded_key\":\"id\"
   },
   \"externally_managed\":false,
   \"group_by_parent\":null,
   \"group_by_study_to_delete\":true,
   \"group_by_submission_to_delete\":null,
   \"group_name\":null,
   \"location\":{
      \"transcoded_class\":\"Location\",
      \"transcoded_find_by_name\":\"Library creation freezer\",
      \"transcoded_key\":\"id\"
   },
   \"max_number_of_groups\":null,
   \"max_size\":null,
   \"min_size\":null,
   \"multiplexed\":null,
   \"name\":\"Illumina-C Library preparation222\",
   \"next_pipeline\":null,
   \"paginate\":false,
   \"previous_pipeline\":null,
   \"sorter\":0,
   \"sti_type\":\"LibraryCreationPipeline\",
   \"summary\":true,
   \"workflow\":{
      \"transcoded_class\":\"LabInterface::Workflow\",
      \"item_limit\":null,
      \"locale\":\"External\",
      \"name\":\"Library preparation\",
      \"tasks\":[
         {
            \"transcoded_class\":\"SetDescriptorsTask\",
            \"batched\":null,
            \"interactive\":null,
            \"lab_activity\":true,
            \"location\":null,
            \"name\":\"Initial QC\",
            \"per_item\":null,
            \"sorted\":1,
            \"sti_type\":\"SetDescriptorsTask\"
         },
         {
            \"transcoded_class\":\"SetDescriptorsTask\",
            \"batched\":null,
            \"interactive\":false,
            \"lab_activity\":true,
            \"location\":null,
            \"name\":\"Gel\",
            \"per_item\":false,
            \"sorted\":2,
            \"sti_type\":\"SetDescriptorsTask\"
         },
         {
            \"transcoded_class\":\"SetDescriptorsTask\",
            \"batched\":true,
            \"interactive\":false,
            \"lab_activity\":true,
            \"location\":null,
            \"name\":\"Characterisation\",
            \"per_item\":false,
            \"sorted\":3,
            \"sti_type\":\"SetDescriptorsTask\"
         }
      ]
   },
   \"request_types\":[
      {
         \"transcoded_class\":\"RequestType\",
         \"transcoded_find_by_key\":\"library_creation\"
      },
      {
         \"transcoded_class\":\"RequestType\",
         \"transcoded_find_by_key\":\"illumina_c_library_creation\"
      }
   ]
}"
  end

  def self.build_from_config_object(config)
    klass_name = config["sti_type"] || config["transcoded_class"]
    klass = klass_name.constantize
    pruned_list = ["transcoded_class", "transcoded_find_by_key"]
    if klass.methods.include?("create")
      klass.create(prune_attributes(config, pruned_list))
    else
      instance = klass.new(prune_attributes(config, pruned_list))
      instance
    end
  end

  def self.transcode_from_object(obj)
    if obj.kind_of? Array
      return obj.map {|n| transcode_from_object(n)}
    end
    puts obj.to_json
    updated_obj = {}
    obj.each_pair do |key, value|
      if value.kind_of?(Hash)
        match = ["key", "name"].map do |key_finding_att|
          [key_finding_att, "transcoded_find_by_#{key_finding_att}"]
        end.detect do |key_finding_att, transcoded_key_finding_att|
          !value[transcoded_key_finding_att].nil?
        end
        if match.nil?
          val_obtained = transcode_from_object(value)
          obj[key] = val_obtained
          unless value["transcoded_key"].nil?
            updated_obj[key+"_#{value["transcoded_key"]}"] = obj[key][value["transcoded_key"]]
            obj.delete(key)
          end
        else
          debugger
          key_finding_att = match[0]
          transcoded_key_finding_att = match[1]
          obj[key] = value["transcoded_class"].constantize.send("find_by_#{key_finding_att}!", value[transcoded_key_finding_att])
        end
      elsif value.kind_of?(Array)
        obj[key] = value.map {|n| transcode_from_object(n)}
      end
    end
    obj.merge!(updated_obj)
    obj = build_from_config_object(obj) if obj["transcoded_class"]
    obj
  end

  def get_attributes(obj)
    # ActiveRecord works with NoMethodError in this .attributes call, so it's not enough to
    # check with defined?
    if (defined? obj.attributes || (defined? obj.respond_to? && obj.respond_to?(:attributes)))
      obj.attributes
    elsif obj.instance_variables.length > 0
      Hash[obj.instance_variables.map {|v|[v, obj.instance_variable_get(v)]}]
    else
      obj
    end
  end

  def transcode_to_object(obj, level=0, max_level=10)
    output = {}

    return nil if obj.nil?
    # Pruned from max_level
    return nil if level > max_level

    # Traversing for Arrays
    return obj.map {|n| transcode_to_object(n, level)} if obj.kind_of?(Array)

    # Stores type
    output["transcoded_class"]=obj.class.to_s

    get_attributes(obj).tap do |attr_obj|
      unless (attr_obj.kind_of?(Hash))
        # Any basic type (String, Fixnum...)
        return attr_obj
      end
      if (level >= 1)
        # Any non-root node with key or name is considered a leaf node (refers to another instance)
        attr_obj.keys.each do |key|
          if ["key", "name"].include?(key)
            output["transcoded_find_by_#{key.to_s}"] = obj[key]
            return output
          end
        end
      end
    end.each_pair do |key, value|
      if key.match(/_id$/)
        key = key.gsub(/_id$/, "").gsub(/^@/,"")
        # The method could be not present
        if obj.methods.include?(key)
          output[key] = transcode_to_object(obj.try(key), level+1)
          #output[key]["transcoded_key"] = "id" unless output[key].nil?
        end
      elsif (value.kind_of?(Hash))
        output[key] = transcode_to_object(obj[key], level+1)
      else
        output[key] = transcode_to_object(value, level+1)
      end
    end

    if output.keys.length == 1 && (!output["transcoded_class"].nil?)
      output = obj
    end
    output
  end
end
