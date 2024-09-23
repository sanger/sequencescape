# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/assets_helper'

describe BatchesHelper do
  describe '#each_action' do
    subject { subject { helper.each_action(batch) } }

    context 'with a pending batch' do
      let(:batch) { build :batch, state: 'pending' }
      let(:fail_link) do
        [
          'Fail batch or requests',
          '#',
          false,
          'Batches can not be failed when pending. Try reset batch under edit instead'
        ]
      end

      it 'yields a disabled fail link' do
        expect { |b| helper.each_action(batch, &b) }.to yield_with_args(*fail_link)
      end
    end

    context 'with a release batch' do
      let(:batch) { build_stubbed :batch, state: 'released' }
      let(:fail_link) { ['Fail batch or requests', { action: :fail, id: batch.id }, true, nil] }

      it 'yields an active fail link' do
        expect { |b| helper.each_action(batch, &b) }.to yield_with_args(*fail_link)
      end
    end

    context 'with potential tasks' do
      def stage_link(id)
        { action: :stage, batch_id: nil, controller: :workflows, id:, workflow_id: pipeline.workflow.id }
      end
      let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }
      let(:batch) { build :batch, state: 'pending', pipeline: }

      let(:task1) { ['Specify Dilution Volume', stage_link(0), true, nil] }
      let(:task2) { ['Add Spiked in control', stage_link(1), true, nil] }
      let(:task3) { ['Set descriptors', stage_link(2), true, nil] }
      let(:fail_link) do
        [
          'Fail batch or requests',
          '#',
          false,
          'Batches can not be failed when pending. Try reset batch under edit instead'
        ]
      end

      it 'yields task links' do
        expect { |b| helper.each_action(batch, &b) }.to yield_successive_args(task1, task2, task3, fail_link)
      end
    end
  end
end
