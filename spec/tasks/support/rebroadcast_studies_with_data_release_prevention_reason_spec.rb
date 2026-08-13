# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'support:rebroadcast_with_data_release_prevention_reason', type: :task do
  let(:task_name) { self.class.top_level_description }
  let(:task) { Rake::Task[task_name] }

  # Helper: create a study with data_release_prevention_reason set
  def create_study_with_prevention_reason(prevention_reason: 'Protecting IP - DAC approval required')
    create(:study).tap do |study|
      study.study_metadata.update!(
        data_release_strategy: 'not applicable',
        data_release_timing: 'never',
        data_release_prevention_reason: prevention_reason,
        data_release_prevention_approval: 'Yes'
      )
    end
  end

  before do
    Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
    Rake::Task[:environment].clear if Rake::Task.task_defined?(:environment)
    Rake.load_rakefile('tasks/support/rebroadcast_studies_with_data_release_prevention_reason.rake')
    Rake::Task.define_task(:environment)
    Rake::Task[task_name].reenable
    ENV.delete('DRY_RUN')
  end

  after { ENV.delete('DRY_RUN') }

  context 'when there are no studies with a data_release_prevention_reason' do
    let(:study_without_reason) { create(:study) }

    before { study_without_reason }

    it 'reports finding 0 studies' do
      expect { task.invoke }.to output(/Found 0 studies/).to_stdout
    end

    it 'does not rebroadcast any study', :warren do
      Warren.handler.clear_messages
      expect { task.invoke }.not_to change(Warren.handler.messages, :count)
    end
  end

  context 'when studies have a data_release_prevention_reason' do
    let(:study) { create_study_with_prevention_reason }

    before { study }

    it 'reports the count of matching studies' do
      expect { task.invoke }.to output(/Found 1 studies/).to_stdout
    end

    it 'outputs the study id and name' do
      expect { task.invoke }.to output(
        /Rebroadcasting Study #{study.id} \(#{Regexp.escape(study.name)}\)/
      ).to_stdout
    end

    it 'outputs the prevention reason' do
      expect { task.invoke }.to output(
        /Reason: #{Regexp.escape(study.study_metadata.data_release_prevention_reason)}/
      ).to_stdout
    end

    it 'calls rebroadcast on the study', :warren do
      Warren.handler.clear_messages
      expect { task.invoke }.to change(Warren.handler.messages, :count).by(1)
    end

    it 'outputs Done at the end' do
      expect { task.invoke }.to output(/Done\./).to_stdout
    end
  end

  context 'when only some studies have a data_release_prevention_reason' do
    let(:studies_with_reason) { Array.new(2) { create_study_with_prevention_reason } }
    let(:study_without_reason) { create(:study) }

    before do
      studies_with_reason
      study_without_reason
    end

    it 'reports only the count of matching studies' do
      expect { task.invoke }.to output(/Found 2 studies/).to_stdout
    end

    it 'calls rebroadcast exactly once per matching study', :warren do
      Warren.handler.clear_messages
      expect { task.invoke }.to change(Warren.handler.messages, :count).by(2)
    end
  end

  context 'when DRY_RUN=true' do
    let(:study) { create_study_with_prevention_reason }

    before do
      study
      ENV['DRY_RUN'] = 'true'
    end

    it 'does not call rebroadcast', :warren do
      Warren.handler.clear_messages
      expect { task.invoke }.not_to change(Warren.handler.messages, :count)
    end

    it 'outputs (dry run) for each matching study' do
      expect { task.invoke }.to output(/\(dry run\)/).to_stdout
    end

    it 'still outputs the study details' do
      expect { task.invoke }.to output(
        /Rebroadcasting Study #{study.id} \(#{Regexp.escape(study.name)}\)/
      ).to_stdout
    end
  end
end
