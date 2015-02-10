#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
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
