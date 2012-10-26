module ::Core::Io::Collection
  def as_json(options = {})
    results, stream = options.delete(:object), options[:stream]
    options[:handled_by].generate_json_actions(results, options)

    stream.attribute(:size, size_for(results))
    stream.array(options[:response].io.json_root.to_s.pluralize, results) do |stream, o|
      output_object(stream, o, options)
    end
  end

  def output_object(stream, object, options)
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
  private :output_object

  def size_for(results)
    results.size
  end
  private :size_for
end
