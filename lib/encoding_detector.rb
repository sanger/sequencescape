# frozen_string_literal: true

# Detect encodings of arbitrary strings for later conversion.
#
# This is a naive implementation that works by trying to encode the string
# to UTF-8 using a list of known encodings, and scoring the results based
# on the number of invalid characters and total length of the resulting string.
# The shorter the resulting string, the more likely it is to be valid.
# Invalid characters are penalised more heavily to avoid false positives and
# assist with UTF-16 detection (which produces shorter strings).
module EncodingDetector
  # A later encoding will ONLY be chosen IF it scores better than an earlier one
  ENCODINGS = %w[UTF-8 ISO-8859-1 UTF-16].freeze

  MAX_SCORE = Float::INFINITY
  INVALID_CHARACTER = '�'

  # Detect the encoding of the given content from the list of known encodings.
  #
  # @param content [String] The string whose encoding is to be detected
  # @return [Hash] A hash containing the detected encoding and inverted_score level
  def self.detect(content)
    best_guess = { inverted_score: MAX_SCORE, encoding: 'UNKNOWN' }
    ENCODINGS.each do |encoding|
      result = test_encoding(content, encoding)
      best_guess = result if result[:inverted_score] < best_guess[:inverted_score]
    end
    best_guess
  end

  def self.score_encoding(content, encoding)
    return { inverted_score: MAX_SCORE, encoding: encoding } if content.blank?

    # The shorter the resulting string, the more likely it is to be valid, unescaped text adds characters
    total_chars = content.length

    # Invalid characters reduce inverted_score
    invalid_chars = content.count(INVALID_CHARACTER)

    # Calculate a score based on the above
    inverted_score = (total_chars + (invalid_chars * 10)) # penalise invalid chars more

    # Return the score as a hash
    {
      inverted_score: inverted_score,
      encoding: encoding,
      _total_chars: total_chars,
      _invalid_chars: invalid_chars
    }
  end

  def self.test_encoding(content, encoding)
    # Try to encode the content to UTF-8 using the specified encoding
    encoded_content = content.dup.force_encoding(encoding)
      .encode('UTF-8', invalid: :replace, undef: :replace, replace: INVALID_CHARACTER)

    score = score_encoding(encoded_content, encoding)
    inverted_score = score[:inverted_score]
    { encoding:, inverted_score: }
  end

  # Convert the given content to UTF-8, using the detected encoding if possible.
  # If the encoding cannot be detected, invalid characters will be replaced with
  # the unicode replacement character (�).
  #
  # @param content [String] The string to be converted to UTF-8
  # @return [String] The content converted to UTF-8, with invalid characters replaced
  def self.convert_to_utf8(content)
    detection = detect(content)
    if detection[:inverted_score] < MAX_SCORE
      content.force_encoding(detection[:encoding]).encode('UTF-8', invalid: :replace, undef: :replace,
                                                                   replace: INVALID_CHARACTER)
    else
      # If detection fails, replace unknown characters with a unicode replacement character
      content.encode('UTF-8', invalid: :replace, undef: :replace, replace: INVALID_CHARACTER)
    end
  end
end
