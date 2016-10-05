module SampleManifestExcel
  module SpecialisedFields
    class TagGroupCache

      attr_reader :cache 
      def initialize
        @cache ||= Hash.new do |h, _name|
          h[_name] = ::TagGroup.include_tags.find_by_name(_name)
        end
      end

      def find(name)
        cache[name]
      end
    end
  end
end