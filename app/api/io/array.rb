# frozen_string_literal: true
# Provides tools for paginating Array objects
class Io::Array
  extend Core::Io::Collection

  def self.size_for(collection)
    collection.size
  end
end
