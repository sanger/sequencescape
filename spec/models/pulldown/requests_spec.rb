# frozen_string_literal: true

require 'rails_helper'

describe Pulldown::Requests do
  let(:bait_library) do
    create(:bait_library,
           bait_library_type: create(:bait_library_type,
                                     category: 'standard'))
  end

  %i[wgs sc isc].each do |request_type|
    context request_type.to_s.upcase do
      setup do
        # I moved it here from minitest unit tests
        # but these libraries do not exist, test was never finished
        @request = create(:"pulldown_#{request_type}_request")
        @request.asset.aliquots.each { |a| a.update!(project: create(:project)) }
      end
    end
  end
end
