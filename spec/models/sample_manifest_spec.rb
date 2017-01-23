require "rails_helper"

RSpec.describe SampleManifest, :type => :model do

  subject do
    File.open('./test/data/invalid_tube_sample_manifest.csv') do |f|
      sm = create :tube_sample_manifest_with_samples, uploaded: f
      sm.samples.each_with_index do |sample, index|
        sample.update_attributes(sanger_sample_id: "tube_sample_#{index+1}")
        sample.primary_receptacle.update_attributes!(barcode: "8#{index+1}")
      end
      sm
    end
  end

  let(:user) { create :user }

  it 'debug stuff because' do
    subject.process(user)
    Delayed::Worker.new.work_off
    expect(subject.reload.state).to eq 'failed'
    expect(subject.last_errors.join(' ')).to include "Incorrect string value"
  end
end
