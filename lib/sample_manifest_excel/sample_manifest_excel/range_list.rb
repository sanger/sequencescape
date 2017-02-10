module SampleManifestExcel
  ##
  # A list of ranges which can be added to a Worksheet
  # and used by the validations.
  class RangeList
    include Enumerable
    include Comparable

    attr_reader :ranges

    ##
    # Creates a hash of ranges.
    # Each key is the range name and each value is a
    # has of range options.
    # The row that the range appears on is defined by the index of the range.
    def initialize(ranges_data = {})
      @ranges = create(ranges_data)
    end

    def each(&block)
      ranges.each(&block)
    end

    ##
    # Find a range by it's key.
    def find_by(key)
      ranges[key] || ranges[key.to_s]
    end

    ##
    # Each range needs a worksheet name to be used as an absolute reference.
    # for when it is added to a validation on another worksheet.
    def set_worksheet_names(worksheet_name)
      each { |_k, range| range.set_worksheet_name(worksheet_name) }
      self
    end

    ##
    # A RangeList is only valid if it contains at least one range object.
    def valid?
      ranges.any?
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      ranges <=> other.ranges
    end

  private

    def create(ranges_data)
      {}.tap do |ranges|
        ranges_data.each_with_index do |(name, options), i|
          ranges[name] = SampleManifestExcel::Range.new(options: options, first_row: i + 1)
        end
      end
    end
  end
end
