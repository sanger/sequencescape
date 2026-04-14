# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Descriptor do
  describe '#validate_value' do
    subject(:errors) { descriptor.validate_value(value) }

    let(:feature_flag) { :y25_105_validate_descriptor_required_field }

    before do
      # By default, disable the feature flag
      allow(Flipper).to receive(:enabled?).with(feature_flag).and_return(false)
    end

    context 'when kind is Date' do
      context 'when required is true' do
        let(:descriptor) { described_class.new(name: 'Some expiry', kind: 'Date', required: true) }

        context 'with a valid ISO 8601 date' do
          let(:value) { '2026-06-01' }

          it { is_expected.to be_empty }
        end

        context 'with a blank value' do
          let(:value) { '' }

          context 'when the feature flag is enabled' do
            before do
              allow(Flipper).to receive(:enabled?).with(feature_flag).and_return(true)
            end

            it { is_expected.to contain_exactly('Some expiry is required') }
          end

          context 'when the feature flag is disabled' do
            before do
              allow(Flipper).to receive(:enabled?).with(feature_flag).and_return(false)
            end

            it { is_expected.to be_empty }
          end
        end

        context 'with an invalid date string' do
          let(:value) { 'not-a-date' }

          it {
            is_expected.to contain_exactly(
              "'not-a-date' is not a valid date for Some expiry (expected YYYY-MM-DD)"
            )
          }
        end

        context 'with a date in the wrong format (DD/MM/YYYY)' do
          let(:value) { '01/06/2026' }

          it {
            is_expected.to contain_exactly(
              "'01/06/2026' is not a valid date for Some expiry (expected YYYY-MM-DD)"
            )
          }
        end

        context 'with a year too far in the past' do
          let(:value) { '1989-06-01' }

          it {
            is_expected.to contain_exactly(
              'Date year for Some expiry must be between 1990 and 2100 (got 1989)'
            )
          }
        end

        context 'with a year too far in the future' do
          let(:value) { '2101-06-01' }

          it {
            is_expected.to contain_exactly(
              'Date year for Some expiry must be between 1990 and 2100 (got 2101)'
            )
          }
        end

        context 'with a typo in the year (e.g., 62026 instead of 2026)' do
          let(:value) { '62026-06-01' }

          it {
            is_expected.to contain_exactly(
              "'62026-06-01' is not a valid date for Some expiry (expected YYYY-MM-DD)"
            )
          }
        end
      end

      context 'when required is false' do
        let(:descriptor) { described_class.new(name: 'Some expiry', kind: 'Date', required: false) }

        context 'with a blank value' do
          let(:value) { '' }

          it { is_expected.to be_empty }
        end

        context 'with a valid ISO 8601 date' do
          let(:value) { '2026-06-01' }

          it { is_expected.to be_empty }
        end

        context 'with an invalid date string' do
          let(:value) { 'not-a-date' }

          it {
            is_expected.to contain_exactly(
              "'not-a-date' is not a valid date for Some expiry (expected YYYY-MM-DD)"
            )
          }
        end

        context 'with a year sanity check failure' do
          let(:value) { '62026-06-01' }

          it {
            is_expected.to contain_exactly(
              "'62026-06-01' is not a valid date for Some expiry (expected YYYY-MM-DD)"
            )
          }
        end
      end
    end

    context 'when kind is Text' do
      let(:descriptor) { described_class.new(name: 'Comment', kind: 'Text', required: false) }
      let(:value) { 'any free text' }

      it { is_expected.to be_empty }
    end

    context 'when kind is Selection' do
      let(:descriptor) { described_class.new(name: 'Workflow', kind: 'Selection', required: false) }
      let(:value) { 'Standard' }

      it { is_expected.to be_empty }
    end
  end
end
