# frozen_string_literal: true

# Where schemas come from, such as files in the repository or a schema
# registry. Subclasses implement #fetch.
class Schemas::Source
  # Raised when a source doesn't hold the schema asked for
  class NotFound < StandardError
  end

  # Fetches one version of a schema.
  #
  # @param subject [String] the schema's name
  # @param version [Integer] the schema's version
  # @return [Schemas::Schema] the schema text and its type
  # @raise [NotFound] if the source doesn't hold that version of the schema
  def fetch(subject, version)
    raise NotImplementedError, 'abstract method'
  end
end
