# frozen_string_literal: true

module Pulldown::Requests
  # Sequences capute
  # See ISC
  # Legacy version where samples were subject to pulldown before
  # pooling. Used more bait.
  class ScLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end
end
