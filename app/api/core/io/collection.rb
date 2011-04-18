module ::Core::Io::Collection
  def as_json(options = {})
    results      = options.delete(:object)
    uuids_to_ids = options[:uuids_to_ids]
    object_json  = results.map do |o|
      ::Core::Io::Registry.instance.lookup_for_object(o).object_json(o, uuids_to_ids, options)
    end

    {
      options[:response].io.json_root.to_s.pluralize => object_json,
      :size         => size_for(results),
      :uuids_to_ids => uuids_to_ids
    }
  end

  def size_for(results)
    results.size
  end

  def post_process(json)
    # Nothing is done here!
  end
end
