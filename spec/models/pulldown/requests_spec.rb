require 'rails_helper'

describe Pulldown::Requests do
  [:wgs, :sc, :isc].each do |request_type|
    context request_type.to_s.upcase do
      setup do
        # I moved it here from minitest unit tests
        # but these libraries do not exist, test was never finished
        @request = create(:"pulldown_#{request_type}_request")
        @request.asset.aliquots.each { |a| a.update_attributes!(project: create(:project)) }
      end
    end
  end

  it 'knows its #billing_product_identifier' do
    request = Pulldown::Requests::IscLibraryRequest.new
    request.request_metadata.bait_library = BaitLibrary.first
    expect(request.billing_product_identifier).to eq 'standard'
  end
end
