module ::Core::Io::Collection
  def as_json(options = {})
    results, base_stream = options[:object], options[:stream]

    base_stream.attribute(:size, size_for(results))
    base_stream.array(options[:response].io.json_root.to_s.pluralize, results) do |stream, object|
      stream.open do
        ::Core::Io::Registry.instance.lookup_for_object(object).object_json(
          object, options.merge(
            :stream => stream,
            :target => object,
            :nested => true
          )
        )
      end
    end
  end
end
