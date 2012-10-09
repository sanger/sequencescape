module ::Core::Io::Collection
  def as_json(options = {})
    results      = options.delete(:object)
    object_json  = results.map do |o|
      ::Core::Io::Registry.instance.lookup_for_object(o).object_json(o, options)
    end

    {
      options[:response].io.json_root.to_s.pluralize => object_json,
      :size => size_for(results)
    }
  end

  def size_for(results)
    results.size
  end

  def post_process(json)
    # Nothing is done here!
  end
end
