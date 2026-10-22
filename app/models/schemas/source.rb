# frozen_string_literal: true

# Where schemas come from, such as files in the repository or a schema
# registry. Subclasses implement #fetch.
class Schemas::Source
  # Raised when a source doesn't hold the schema asked for
  class NotFound < Schemas::Error
  end

  # Raised when a source can't be reached or doesn't answer in time
  class Unavailable < Schemas::Error
  end

  # Fetches one version of a schema.
  #
  # @param subject [String] the schema's name
  # @param version [Integer, :latest] the schema's version, or :latest for
  #   the highest version the source holds
  # @return [Schemas::Schema] the schema text, its type and its version
  # @raise [NotFound] if the source doesn't hold that version of the schema
  def fetch(subject, version)
    raise NotImplementedError, 'abstract method'
  end
end
