# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessionHelper, type: :helper do
  describe '#accessioning_enabled?' do
    around do |example|
      original = configatron.accession_samples
      example.run
      configatron.accession_samples = original
    end

    it 'returns true when configatron.accession_samples is true' do
      configatron.accession_samples = true
      expect(helper.accessioning_enabled?).to be true
    end

    it 'returns false when configatron.accession_samples is false' do
      configatron.accession_samples = false
      expect(helper.accessioning_enabled?).to be false
    end
  end

  describe '#permitted_to_accession?' do
    let(:object) { double(:object) } # Could be a Study or a Sample # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when the current user is does not have accession permission' do
      let(:user) { create(:user) }

      it 'returns false' do
        expect(helper.permitted_to_accession?(object)).to be false
      end
    end

    context 'when the current user has accession permission' do
      let(:user) { create(:admin) }

      before do
        allow(user).to receive(:can?).with(:accession, object).and_return(true)
      end

      it 'returns true' do
        expect(helper.permitted_to_accession?(object)).to be true
      end
    end

    context 'when there is no current user' do
      let(:user) { nil }

      it 'returns false' do
        expect(helper.permitted_to_accession?(object)).to be false
      end
    end
  end
end
