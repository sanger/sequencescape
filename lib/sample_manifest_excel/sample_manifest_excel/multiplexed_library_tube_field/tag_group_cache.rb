module SampleManifestExcel
  module MultiplexedLibraryTubeField
    class TagGroupCache < Base
      attr_reader :cache
      def initialize
        @cache ||= Hash.new do |h, name|
          h[name] = ::TagGroup.include_tags.find_by(name: name)
        end
      end

      def find(name)
        cache[name]
      end
    end
  end
end
