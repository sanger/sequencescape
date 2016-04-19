module SampleManifestExcel
  class RangeList

  	include Enumerable

  	attr_reader :ranges

  	def initialize(ranges={})
  	  @ranges = create(ranges)
  	end

  	def each(&block)
      ranges.each(&block)
    end

    def find_by(key)
      ranges[key]
    end

    private

    def create(ranges)
      ranges.each_with_index do |(name, options), i|
      	ranges[name] = SampleManifestExcel::Range.new(options, i+1)
      end
    end
  end
end