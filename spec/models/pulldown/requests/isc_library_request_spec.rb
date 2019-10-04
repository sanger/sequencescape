# frozen_string_literal: true

require 'rails_helper'

describe Pulldown::Requests::IscLibraryRequest do
  subject { build :isc_request, bait_library: bait_library }

  context 'with a active bait library' do
    let(:bait_library) { create(:bait_library) }

    it { is_expected.to be_valid }
  end

  context 'with a inactive bait library' do
    let(:bait_library) { create(:bait_library, visible: false) }

    it { is_expected.not_to be_valid }

    it 'explains the problem' do
      subject.valid?
      expect(subject.errors.full_messages).to include('Request metadata bait library Validation failed: Bait library is no longer available.')
    end
  end
end
