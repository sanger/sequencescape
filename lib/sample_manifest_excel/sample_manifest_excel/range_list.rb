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
      ranges.each do |name, value|
      	ranges[name] = SampleManifestExcel::Range.new(value["options"], value["row"])
      end
    end
  end
end