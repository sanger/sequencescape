require 'rails_helper'

RSpec.describe PickList, type: :model do
  let(:wells) { create_list :well, 2 }

  before do
    create :cherrypick_submission_template
  end

  describe '::create' do
    subject { described_class.create(receptacles: wells, asynchronous: asynchronous) }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it { is_expected.to be_pending }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      xit { is_expected.to be_built }
    end
  end

  describe '.receptacles' do
    subject { described_class.create(receptacles: wells, asynchronous: asynchronous).receptacles }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      xit { is_expected.to eq wells }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      xit { is_expected.to eq wells }
    end
  end
end
