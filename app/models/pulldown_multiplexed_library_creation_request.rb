# frozen_string_literal: true
class PulldownMultiplexedLibraryCreationRequest < CustomerRequest # rubocop:todo Style/Documentation
  # override default behavior to not copy the aliquots
  def on_started; end
end
