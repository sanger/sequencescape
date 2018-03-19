# frozen_string_literal: true

# Class OligoEnumerator provides a simple means of generating unique
# tag sequences for testing and development
#
# @author Genome Research Ltd.
#
class OligoEnumerator
  include Enumerable
  #
  # Generate an oligo enumerator
  #
  # @param [Integer] size The number of tags to generate
  #
  def initialize(size)
    @size = size
  end

  def last
    tag(@size)
  end

  def each
    @size.times do |i|
      yield tag(i)
    end
  end

  def tag(i)
    i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
  end
end
