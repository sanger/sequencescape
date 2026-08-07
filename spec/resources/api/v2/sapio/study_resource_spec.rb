# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sapio/study_resource'

RSpec.describe Api::V2::Sapio::StudyResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:study) }

  # Mutability
  it { expect(described_class.mutable?).to be(true) }

  # Model Name
  it { is_expected.to have_model_name 'Study' }

  # Attributes
  it { is_expected.to have_readonly_attribute :name }
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :created_at }
  it { is_expected.to have_readonly_attribute :updated_at }
  it { is_expected.to have_readonly_attribute :blocked }
  it { is_expected.to have_readwrite_attribute :state }
  it { is_expected.to have_readwrite_attribute :externally_managed }
  it { is_expected.to have_readonly_attribute :ethically_approved }
  it { is_expected.to have_readonly_attribute :enforce_data_release }
  it { is_expected.to have_readonly_attribute :enforce_accessioning }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:study_metadata).with_class_name('StudyMetadata') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }

  # Filters
  it { is_expected.to filter(:name) }

  describe '.wildcard_query?' do
    # This method is used for search algorithm selection:
    # wildcard_name vs contains_name
    it 'returns true when wildcards are outside quotes' do
      expect(described_class.wildcard_query?('abc* def? "ghi" "jkl*"')).to be(true)
    end

    it 'returns false when wildcards are only inside balanced quotes' do
      expect(described_class.wildcard_query?('abc "def" "ghi*" "jkl?"')).to be(false)
    end

    it 'returns true when an unbalanced quoted phrase has wildcards after it' do
      expect(described_class.wildcard_query?('abc "def* ghi')).to be(true)
    end

    it 'returns true when wildard meets quote' do
      expect(described_class.wildcard_query?('abc *"def" ghi')).to be(true)
    end

    it 'returns true when wildard is met by quote' do
      expect(described_class.wildcard_query?('abc "def"* ghi')).to be(true)
    end
  end
end
