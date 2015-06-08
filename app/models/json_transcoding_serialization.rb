module JsonTranscodingSerialization
  def self.included(base)
    base.instance_eval do |klass|
      def transcoding_with_methods(list)
        self.instance_eval {|k| @list_transcoding = list}
      end
    end
    base.class_eval do |klass|
      @list_transcoding = []

      attr_reader :list_transcoding

      def attribute_hash
        transcoded_object = transcode(self, [])
        debugger
        [self.class.instance_variable_get("@list_transcoding")].flatten.compact.each do |path|
          processables_keys = [path].flatten
          value = transcode(processables_keys.reduce(self) do |memo, obj|
            if (!memo.nil? && memo.methods.include?(obj))
              memo.send(obj)
            end
          end, [])
          last_key = processables_keys.pop
          processables_keys.reduce(transcoded_object) do |memo, obj|
            memo[obj] = {} if memo[obj].nil?
            memo[obj]
          end[last_key] = value
        end
        transcoded_object
      end
      def serialize
        attribute_hash.to_json
      end
    end
  end


  private

  def traverse_pairs(obj)
    obj.instance_variables.each do |var|
      if obj.methods.include?(var.to_s.delete("@"))
        yield var.to_s, obj.instance_variable_get(var)
      end
    end
  end

  def transcode(obj, cycle_detection_list=[])
    output = {}

    return nil if obj.nil?
    # Stop if we are in a cycling loop
    return nil if cycle_detection_list.include?(obj)

    # Key or Name instead of full object for inherited
    unless cycle_detection_list.empty?
      [:key, :name].each do |key|
        if obj[key]
          output[key] = obj[key]
          return output
        end
      end
    end
    cycle_detection_list.push(obj)

    # Traversing for Arrays
    return obj.map {|n| transcode(n, cycle_detection_list)} if obj.kind_of?(Array)

    if defined? obj.attributes
      obj.attributes.each_pair do |key, value|
        if key.match(/_id$/)
          transcoded_key = key.gsub(/_id$/, "")
          # Delegate the value obtaining from rails
          if obj.methods.include?(transcoded_key)
            output[transcoded_key] = transcode(obj.try(transcoded_key), cycle_detection_list)
          end
        elsif (value.type == Hash)
          output[key] = transcode(obj.try(key), cycle_detection_list)
        else
          output[key] = value
        end
      end
    end
    ["id", "created_at", "updated_at"].each {|s| output.delete(s) }
    output
  end
end
