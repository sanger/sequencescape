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

    def set_worksheet_names(worksheet_name)
      each {|k, range| range.set_worksheet_name(worksheet_name)}
      self
    end

    def valid?
      ranges.any?
    end

    private

    def create(ranges_data)
      {}.tap do |ranges|
        ranges_data.each_with_index do |(name, options), i|
        	ranges[name] = SampleManifestExcel::Range.new(options: options, first_row: i+1)
        end
      end
    end
  end
end