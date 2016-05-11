module SampleManifestExcel
  class RangeList

  	include Enumerable

  	attr_reader :ranges

  	def initialize(ranges_data={})
  	  @ranges = create(ranges_data)
  	end

  	def each(&block)
      ranges.each(&block)
    end

    def find_by(key)
      ranges[key]
    end

    def set_absolute_references(worksheet)
      each {|k, range| range.set_absolute_reference(worksheet)}
      self
    end

    private

    def create(ranges_data)
      {}.tap do |ranges|
        ranges_data.each_with_index do |(name, options), i|
        	ranges[name] = SampleManifestExcel::Range.new(options, i+1)
        end
      end
    end
  end
end