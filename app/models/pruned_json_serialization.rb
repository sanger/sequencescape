module PrunedJsonSerialization

  def self.pipeline_attribute_hash(pipeline)
    prune_list = ["id", "created_at", "updated_at"]

    transcoded_object = prune_attributes(transcode_to_object(pipeline), prune_list)
    transcoded_object["workflow"] = prune_attributes(transcode_to_object(pipeline.workflow), prune_list + ["pipeline"])
    unless pipeline.workflow.nil?
      transcoded_object["workflow"]["tasks"] = prune_attributes(transcode_to_object(pipeline.workflow.tasks), prune_list)
      pipeline.workflow.tasks.each_with_index do |task, pos|
        transcoded_object["workflow"]["tasks"][pos]["descriptors"] = prune_attributes(transcode_to_object(task.descriptors), prune_list)
      end
    end
    transcoded_object["request_types"] = prune_attributes(transcode_to_object(pipeline.request_types,1), prune_list)

    transcoded_object
  end

  def self.render(pipeline)
    pipeline_attribute_hash(pipeline).to_json
  end

  def self.build(json)
    obj = PrunedJsonSerialization::transcode_from_object(JSON.parse(json))
    if obj.kind_of?(Array)
      obj.each {|o| o.save!}
    else
      obj.save!
    end
  end

  def self.prune_attributes(obj, attributes_list=nil)
    if obj.kind_of? Array
      obj.map{|n| prune_attributes(n, attributes_list)}
    end
    unless obj.nil? ||  attributes_list.nil?
      attributes_list.each do |s|
        obj.delete(s.to_s)
        obj.delete(s)
      end
    end
    obj
  end


  def self.build_from_config_object(config)
    klass_name = config["sti_type"] || config["transcoded_class"]
    klass = klass_name.constantize
    pruned_list = ["transcoded_class", "transcoded_find_by_key"]
    if klass.methods.include?("create")
      instance = klass.create(prune_attributes(config, pruned_list))
    else
      instance = klass.new(prune_attributes(config, pruned_list))
    end
    instance.save!
    instance
  end

  def self.process_object(obj)
    if obj.kind_of? Hash
      ["key", "name"].map do |key_finding_att|
        [key_finding_att, "transcoded_find_by_#{key_finding_att}"]
      end.detect do |key_finding_att, transcoded_key_finding_att|
        !obj[transcoded_key_finding_att].nil?
      end.tap do |match|
        return match if match.nil?
        key_finding_att = match[0]
        transcoded_key_finding_att = match[1]
        yield obj["transcoded_class"].constantize.send("find_by_#{key_finding_att}!", obj[transcoded_key_finding_att])
      end
    end
  end

  def self.transcode_from_object(obj)
    if obj.kind_of? Array
      return obj.map {|n| transcode_from_object(n)}
    end

    process_object(obj) {|val| return val}

    if obj.kind_of?(Hash)
      updated_obj = {}
      obj.each_pair do |key, value|
        if value.kind_of?(Hash)
          match = process_object(value) {|val| obj[key] = val}
          if match.nil?
            val_obtained = transcode_from_object(value)
            obj[key] = val_obtained
            unless value["transcoded_key"].nil?
              updated_obj[key+"_#{value["transcoded_key"]}"] = obj[key][value["transcoded_key"]]
              obj.delete(key)
            end
          end
        elsif value.kind_of?(Array)
          obj[key] = value.map {|n| transcode_from_object(n)}
        end
      end
      obj.merge!(updated_obj)
      obj = build_from_config_object(obj) if obj["transcoded_class"]
    end
    obj
  end

  def self.get_attributes(obj)
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

  def self.transcode_to_object(obj, level=0, max_level=10)
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
