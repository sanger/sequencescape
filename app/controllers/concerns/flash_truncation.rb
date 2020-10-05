# frozen_string_literal: true

# Module FlashTruncation provides the truncate_flash method to automatically
# trim long flash messages to prevent them from overflowing the cookie
#
# @author Genome Research Ltd.
#
module FlashTruncation
  # Encoding a json string results in a two-byte overhead for the " either side.
  # Taking this into account is strictly unnecessary, as we've already got a bit
  # of overhead built in, but lets keep things as predictable as possible.
  STRING_OVERHEAD = 2

  #
  # Truncates the flash message to avoid an ActionDispatch::Cookies::CookieOverflow.
  # Maximum cookie size is checked against ActionDispatch::Cookies::MAX_COOKIE_SIZE which is 4096
  # bytes; however:
  # - This is the size of the session cookie post encryption, which inflates the size
  # - This cookie also needs to contain other data, such as the session_id, user_uuid and user_name
  #
  # @param [Array, String] message The flash to truncate
  # @param [Integer] max_size The maximum allowed flash size
  #
  # @return [Array, String] The truncated message
  #
  def truncate_flash(message, max_size = max_flash_size)
    return message if message.to_json.bytesize <= max_size

    case message
    when String
      message.truncate(max_size - STRING_OVERHEAD)
    when Array
      truncate_flash_array(message, max_size)
    end
  end

  # The maximum cookie size is 4096 bytes, however this is post-encryption, which increases the size.
  # The value of 2048 was obtained by mapping the size of encrypted strings. In practice 2255 bytes was the
  # largest size, but I rounded down to 2kb to provide a bit of overhead for array serialization, additional
  # flash information to and allow for slight implementation changes.
  def max_flash_size
    2048 - session.to_json.bytesize
  end

  # @see truncate_flash
  # Handles truncation of arrays passed to the flash. This is not intended to be used directly,
  # instead use truncate_flash.
  #
  # @param [Array] array The flash to truncate
  # @param [Integer] max_size The maximum allowed flash size
  #
  # @return [Array] The truncated array
  #
  def truncate_flash_array(array, max_size = max_flash_size)
    array.each_with_object([]) do |message, messages|
      remaining = max_size - messages.to_json.bytesize
      return messages if remaining <= 0

      messages << truncate_flash(message, remaining)
    end
  end
end
