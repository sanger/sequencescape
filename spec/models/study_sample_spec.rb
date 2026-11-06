# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudySample do
  # As the queue broadcast consumer calls it. Creating the records sends
  # other messages, so only messages about the study link itself are counted.
  describe '#broadcast' do
    let(:study_sample) { create(:study_sample, sample:) }
    let(:message_about_link) do
      an_object_having_attributes(record: study_sample)
    end

    before do
      allow(Warren.handler).to receive(:<<)
      study_sample.broadcast
    end

    context 'with a Sequencescape sample' do
      let(:sample) { create(:sample) }

      it 'sends the study link' do
        expect(Warren.handler).to have_received(:<<).with(message_about_link)
      end
    end

    context 'with a Sapio sample (externally managed)' do
      let(:sample) { create(:sample, externally_managed: true) }

      it 'does not send the study link' do
        expect(Warren.handler)
          .not_to have_received(:<<).with(message_about_link)
      end
    end
  end
end
