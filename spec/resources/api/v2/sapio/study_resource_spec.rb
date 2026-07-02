# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sapio/study_resource'

RSpec.describe Api::V2::Sapio::StudyResource, type: :resource do
  describe '.wildcard_query?' do
    # This method is used for search algorithm selection:
    # wildcard_name vs contains_names
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
