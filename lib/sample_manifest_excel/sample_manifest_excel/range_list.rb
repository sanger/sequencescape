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
      ranges.each_with_index do |(name, list_of_options), i|
      	ranges[name] = SampleManifestExcel::Range.new(name, list_of_options).set_position(i+1)
      end
    end
  end
end