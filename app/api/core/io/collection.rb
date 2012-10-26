module ::Core::Io::Collection
  def as_json(options = {})
    results, stream = options.delete(:object), options[:stream]
    options[:handled_by].generate_json_actions(results, options)
    stream[:size] = size_for(results)
    stream.array(options[:response].io.json_root.to_s.pluralize, results) do |stream, o|
      ::Core::Io::Registry.instance.lookup_for_object(o).object_json(o, options.merge(:stream => stream, :target => o, :nested => true))
    end
  end

  def size_for(results)
    results.size
  end
  private :size_for
end
