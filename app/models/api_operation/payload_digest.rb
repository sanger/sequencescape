# frozen_string_literal: true

# Computes the digest of an API operation payload, which tells a repeated
# request from a changed one.
#
# The payload is parsed and written again as compact JSON, with the object
# keys sorted at every level, and the SHA-256 of that text is the digest.
# So key order, whitespace and how a decimal is written (e.g. 1.10 or 1.1)
# don't change the digest, while array order, values, and whether a number
# is an integer or a decimal (1 or 1.0) do.
class ApiOperation::PayloadDigest
  # @param payload [String] the payload as JSON text
  # @return [String] the SHA-256 hex digest, 64 characters
  # @raise [JSON::ParserError] if the payload is not valid JSON
  def self.hexdigest(payload)
    Digest::SHA256.hexdigest(JSON.generate(sorted(JSON.parse(payload))))
  end

  # @param value [Object] a parsed JSON value
  # @return [Object] the value with object keys sorted at every level
  def self.sorted(value)
    case value
    when Hash then value.keys.sort.index_with { |key| sorted(value[key]) }
    when Array then value.map { |item| sorted(item) }
    else value
    end
  end
  private_class_method :sorted
end
