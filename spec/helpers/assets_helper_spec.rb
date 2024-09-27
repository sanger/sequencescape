# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/assets_helper'

describe AssetsHelper do
  before do
    helper.extend(AuthenticatedSystem)
    session[:user] = user.id
    assign(:current_user, user)
  end

  describe '#current_user_can_request_additional_sequencing_on?' do
    subject { helper.current_user_can_request_additional_sequencing_on?(asset) }

    context 'an admin user' do
      let(:user) { create(:admin) }

      context 'with a SampleTube' do
        let(:asset) { create(:sample_tube) }

        it { is_expected.to be false }
      end

      context 'with a LibraryTube' do
        let(:asset) { create(:library_tube) }

        it { is_expected.to be true }
      end

      context 'with a MultiplexedTube' do
        let(:asset) { create(:multiplexed_library_tube) }

        it { is_expected.to be true }
      end
    end

    context 'a manager' do
      let(:user) { create(:manager) }
      let(:asset) { create(:library_tube) }

      it { is_expected.to be true }
    end

    context 'a regular user' do
      let(:user) { create(:user) }
      let(:asset) { create(:library_tube) }

      it { is_expected.to be false }
    end
  end

  describe '#current_user_can_request_additional_library_on?' do
    subject { helper.current_user_can_request_additional_library_on?(asset) }

    context 'an admin user' do
      let(:user) { create(:admin) }

      context 'with a SampleTube' do
        let(:asset) { create(:sample_tube) }

        it { is_expected.to be true }
      end

      context 'with a LibraryTube' do
        let(:asset) { create(:library_tube) }

        it { is_expected.to be false }
      end

      context 'with a MultiplexedTube' do
        let(:asset) { create(:multiplexed_library_tube) }

        it { is_expected.to be false }
      end
    end

    context 'with a manager' do
      let(:user) { create(:manager) }
      let(:asset) { create(:sample_tube) }

      # NOTE: This behaviour changes with the permissions update to be consistent
      # with sequencing.

      it { is_expected.to be true }
    end

    context 'with a regular user' do
      let(:user) { create(:user) }
      let(:asset) { create(:sample_tube) }

      it { is_expected.to be false }
    end
  end
end
