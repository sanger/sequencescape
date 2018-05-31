# frozen_string_literal: true


module Pulldown::Requests
  # Whole genome sequencing library prep.
  # Entire genome is fragmented and prepared for sequencing.
  class WgsLibraryRequest < LibraryCreation
    fragment_size_details(300, 500)
  end
end
