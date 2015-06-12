module PrunedJsonSerialization
  def self.included(base)
    # base.instance_eval do |klass|
    #   class_variable_set(:@@pruned_json_methods_list, [])
    #   def pruned_json_including_methods(list)
    #     class_variable_set(:@@pruned_json_methods_list, list)
    #   end
    #   def self.pruned_json_methods_list
    #     class_variable_get(:@@pruned_json_methods_list)
    #   end
    # end
    base.class_eval do |klass|
      # def attribute_hash2(obj, methods_list=nil)
      #   methods_list = self.class.pruned_json_methods_list if methods_list.nil?

      #   # Adds attributes into the result
      #   traversed_object = traverse_and_prune(obj)

      #   # Adds specified method calls into the result
      #   methods_list.each do |path|
      #     processables_keys = [path].flatten
      #     # Obtains the object corresponding this chain of keys (processable_keys)
      #     value = traverse_and_prune(find_path(obj, processables_keys))

      #     # Updates the result with the object obtained for the keys
      #     assign_value_into_path(traversed_object, processables_keys, value)
      #   end
      #   traversed_object
      # end

      def build_from_pruned_json(json)
        transcode(JSON.parse(json))
      end

      def render_to_pruned_json
        attribute_hash(self).to_json
      end

      def json
      end

    end
  end

  private

  def assign_value_into_path(obj, path, value)
    last_key = path.pop
    hash = path.reduce(obj) do |memo, key_symbol|
      if memo.kind_of? Array
        leaf_list(memo.map{|n| n.send(key_symbol)})
        #memo.each {|l, pos| l[key_symbol] = leaf_list(memo[key_symbol]).map{|n| n.send(key_symbol)}
      else
        memo[key_symbol] = {} if memo[key_symbol].nil?
        memo[key_symbol]
      end
    end
    #
    leaf_list_value = leaf_list(value)
    debugger
    if hash[last_key].kind_of? Array
      hash[last_key].map!{|n, pos| leaf_list_value[pos]}
    else
      hash[last_key] = value unless hash.nil?
    end
  end

  def leaf_list(list)
    if ((list.length==1) && (list[0].kind_of?(Array)))
      leaf_list(list[0])
    else
      list
    end
  end

  def build_path(obj, path)
    path.reduce(obj) do |memo, key_symbol|
      if memo.kind_of? Array
        leaf_list(memo.map{|n| n.send(key_symbol)})
        #memo.each {|l, pos| l[key_symbol] = leaf_list(memo[key_symbol]).map{|n| n.send(key_symbol)}
      else
        memo[key_symbol] = {} if memo[key_symbol].nil?
        memo[key_symbol]
      end
    end
  end

  def find_path(obj, path)
    key_symbol = path[0]
    rest_path = path.slice(1, path.length)

    if (path.nil? || path.empty?)
      return obj
    end

    if obj.kind_of? Array
      if (!obj.first.nil? && (obj.first.methods.include?(key_symbol.to_s) || obj.first.respond_to?(key_symbol.to_s)))
        return obj.map{|n| find_path(n.send(key_symbol), rest_path)}
      end
    elsif (!obj.nil? && (obj.methods.include?(key_symbol.to_s) || obj.respond_to?(key_symbol.to_s)))
      return find_path(obj.send(key_symbol), rest_path)
    end
  end

  #   if path.length == 1
  #     if memo.kind_of? Array
  #       if (!memo.first.nil? && (memo.first.methods.include?(key_symbol.to_s) || memo.first.respond_to?(key_symbol.to_s)))
  #         memo.map{|n| n.send(key_symbol)}
  #       end
  #     elsif (!memo.nil? && (memo.methods.include?(key_symbol.to_s) || memo.respond_to?(key_symbol.to_s)))
  #       memo.send(key_symbol)
  #     end
  #   else
  #     find_path()
  #   end
  #   path.reduce(obj) do |memo, key_symbol|
  #     if memo.kind_of? Array
  #       if (!memo.first.nil? && (memo.first.methods.include?(key_symbol.to_s) || memo.first.respond_to?(key_symbol.to_s)))
  #         memo.map{|n| n.send(key_symbol)}
  #       end
  #     elsif (!memo.nil? && (memo.methods.include?(key_symbol.to_s) || memo.respond_to?(key_symbol.to_s)))
  #       memo.send(key_symbol)
  #     end
  #   end
  # end

  def traverse_and_prune(obj)
    obj = traverse(obj)
    prune_list = ["id", "created_at", "updated_at"]
    if obj.kind_of? Array
      obj.map{|n| prune_attributes(n, prune_list)}
    else
      prune_attributes(obj, prune_list)
    end
  end

  def prune_attributes(obj, attributes_list=nil)
    unless obj.nil? || attributes_list.nil?
      attributes_list.each do |s|
        obj.delete(s.to_s)
        obj.delete(s)
      end
    end
    obj
  end

  def build_from_config(config)
    klass_name = config["sti_type"] || config["transcoded_class"]
    klass = klass_name.constantize.create!(prune_attributes(config, "transcoded_class"))
  end

  def transcode(obj)
    obj.each_pair do |key, value|
      if value.kind_of? Hash
        match = ["key", "name"].map do |key_finding_att|
          [key_finding_att, "transcoded_find_by_#{key_finding_att}"]
        end.detect do |key_finding_att, transcoded_key_finding_att|
          !value[transcoded_key_finding_att].nil?
        end
        if match.nil?
          obj[key] = transcode(value)
        else
          key_finding_att = match[0]
          transcoded_key_finding_att = match[1]
          obj[key] = value["transcoded_class"].constantize.send("find_by_#{key_finding_att}!", value[transcoded_key_finding_att])
        end
      elsif value.kind_of? Array
        obj[key] = value.map {|n| transcode(n)}
      end
    end
    obj = build_from_config(obj) if obj["transcoded_class"]
    obj
  end

  def traverse(obj, level=0, max_level=1)
    output = {}

    return nil if obj.nil?
    # Pruned from max_level
    return nil if level > max_level

    # Traversing for Arrays
    return obj.map {|n| traverse(n, level)} if obj.kind_of?(Array)

    # Stores type
    output["transcoded_class"]=obj.class.to_s

    # Key or Name instead of full object for max_level
    if level >= max_level
      [:key, :name].each do |key|
        if obj[key]
          output["transcoded_find_by_#{key.to_s}"] = obj[key]
          return output
        end
      end
    end

    # ActiveRecord works with NoMethodError in this .attributes call, so it's not enough to
    # check with defined?
    if (defined? obj.attributes || (defined? obj.respond_to? && obj.respond_to?(:attributes)))
      obj.attributes.each_pair do |key, value|
        if key.match(/_id$/)
          key = key.gsub(/_id$/, "")
          # The method could be not present
          if obj.methods.include?(key)
            output[key] = traverse(obj.try(key), level+1)
          end
        elsif (value.class == Hash)
          output[key] = traverse(obj.try(key), level+1)
        else
          output[key] = value
        end
      end
    end
    output
  end
end
