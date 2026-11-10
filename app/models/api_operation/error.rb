# frozen_string_literal: true

# A problem found while processing an operation's payload, located by a JSON
# pointer. It can be raised, or returned in a task's errors, where it is
# recorded as its to_h.
class ApiOperation::Error < StandardError
  # @return [String] the JSON pointer to the part of the payload at fault
  attr_reader :pointer

  # @param pointer [String] the JSON pointer to the part of the payload at fault
  # @param detail [String] what is wrong
  def initialize(pointer, detail)
    super(detail)
    @pointer = pointer
  end

  # @return [String] what is wrong
  def detail
    message
  end

  # @return [Hash] the error as recorded, with :pointer and :detail
  def to_h
    { pointer:, detail: }
  end

  # @param key [Symbol] :pointer or :detail
  def [](key)
    to_h[key]
  end
end
