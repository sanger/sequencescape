# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudySample do
  describe '#broadcast' do
    before { allow(Warren.handler).to receive(:<<) }

    it 'sends the study link of a sample' do
      study_sample = create(:study_sample)
      study_sample.broadcast
      expect(Warren.handler).to have_received(:<<)
        .with(an_object_having_attributes(record: study_sample))
    end

    it 'sends nothing for an externally managed sample' do
      sample = create(:sample, externally_managed: true)
      study_sample = create(:study_sample, sample:)
      study_sample.broadcast
      expect(Warren.handler).not_to have_received(:<<)
        .with(an_object_having_attributes(record: study_sample))
    end
  end
end
