require 'rails_helper'

RSpec.describe 'Warren::BroadcastMessages', warren: true do
  let(:warren) { Warren.handler }

  # Using study and study_metadata as examples

  shared_context 'a self broadcast resource' do
    setup { warren.clear_messages }

    let(:resource_key) { subject.class.name.underscore }
    let(:routing_key) { "test.queue_broadcast.#{resource_key}.#{subject.id}" }

    it 'broadcasts the resource' do
      subject.save!
      expect(warren.messages_matching(routing_key)).to eq(1)
    end
  end

  shared_context 'an associated broadcast class' do
    setup { warren.clear_messages }
    let(:resource_key) { resource.class.name.underscore }
    let(:routing_key) { "test.queue_broadcast.#{resource_key}.#{resource.id}" }

    it 'broadcasts the associated resource' do
      subject.save!
      expect(warren.messages_matching(routing_key)).to eq(1)
    end
  end

  describe 'study' do
    subject { build :study }

    it_behaves_like 'a self broadcast resource'
  end

  context 'study_metadata' do
    subject { resource.study_metadata }

    let!(:resource) { create :study }

    it_behaves_like 'an associated broadcast class'
  end

  context 'order' do
    subject { build :order }

    it_behaves_like 'a self broadcast resource'
  end

  context 'submission' do
    subject { build :submission }

    it_behaves_like 'a self broadcast resource'
  end

  context 'request' do
    subject { build :request }

    it_behaves_like 'a self broadcast resource'
  end

  context 'plate_purpose' do
    subject { build :plate_purpose }

    it_behaves_like 'a self broadcast resource'
  end

  context 'study_sample' do
    subject { build :study_sample }

    it_behaves_like 'a self broadcast resource'
  end

  context 'sample' do
    subject { build :sample }

    it_behaves_like 'a self broadcast resource'
  end

  context 'aliquot' do
    subject { build :aliquot }

    it_behaves_like 'a self broadcast resource'
  end

  context 'tag' do
    subject { build :tag }

    it_behaves_like 'a self broadcast resource'
  end

  context 'project' do
    subject { build :project }

    it_behaves_like 'a self broadcast resource'
  end

  context 'labware' do
    subject { build :labware }

    it_behaves_like 'a self broadcast resource'
  end

  context 'receptacle' do
    subject { build :receptacle }

    it_behaves_like 'a self broadcast resource'
  end

  context 'asset_link' do
    subject { build :asset_link }

    it_behaves_like 'a self broadcast resource'
  end

  context 'well_attribute' do
    subject { resource.well_attribute }

    let!(:resource) { create :well }

    it_behaves_like 'an associated broadcast class'
  end

  context 'batch' do
    subject { build :batch }

    it_behaves_like 'a self broadcast resource'
  end

  context 'batch_request,' do
    subject { build :batch_request }

    it_behaves_like 'a self broadcast resource'
  end

  context 'role' do
    subject { resource.roles.first }

    let!(:resource) { create :study_with_manager }

    it_behaves_like 'an associated broadcast class'
  end

  context 'Role::UserRole' do
    subject { resource.roles.first.user_role_bindings.first }

    let!(:resource) { create :study_with_manager }

    it_behaves_like 'an associated broadcast class'
  end

  context 'reference_genome' do
    subject { build :reference_genome }

    it_behaves_like 'a self broadcast resource'
  end

  context 'messenger' do
    subject { build :messenger }

    setup { warren.clear_messages }
    it_behaves_like 'a self broadcast resource'
    #  let(:routing_key) { subject.routing_key }
    # it 'broadcasts the resource' do
    #   subject.save!
    #   expect(warren.messages_matching(routing_key)).to eq(1)
    # end
  end

  context 'broadcast_event' do
    subject { build :broadcast_event_asset_audit }

    setup { warren.clear_messages }
    it_behaves_like 'a self broadcast resource'

    # let(:routing_key) { "test.event.some_key.#{subject.id}" }

    # it 'broadcasts the resource' do
    #   subject.save!
    #   expect(warren.messages_matching(routing_key)).to eq(1)
    # end
  end
end
