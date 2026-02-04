# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
RSpec.describe 'ebi rake tasks' do # rubocop:disable RSpec/DescribeClass
  let(:process) { instance_double(EBICheck::Process) }
  let(:task) { Rake::Task[task_name] }

  before do
    Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
    Rake::Task[:environment].clear if Rake::Task.task_defined?(:environment)
    Rake.rake_require('tasks/ebi_check')
    Rake::Task.define_task(:environment)
    allow(EBICheck::Process).to receive(:new).and_return(process)
  end

  after do
    %w[study_ids sample_ids study_numbers sample_numbers].each { |k| ENV.delete(k) }
    Rake::Task[task_name].reenable
  end

  describe 'ebi:check_studies' do
    let(:task_name) { 'ebi:check_studies' }

    context 'with no arguments' do
      it 'prints usage and exits with status 1' do
        expect do
          expect do
            task.invoke
          end.to output(/Usage: bundle exec rake ebi:check_studies/).to_stdout
        end.to raise_error(SystemExit) { |e|
          expect(e.status).to eq(1)
        }
      end
    end

    context 'with study_ids' do
      before do
        ENV['study_ids'] = '123,456'
        allow(process).to receive(:studies_by_ids)
      end

      it 'processes studies by IDs' do
        expect { task.invoke }.to output(/Processing Study IDs/).to_stdout
        expect(process).to have_received(:studies_by_ids).with(%w[123 456])
      end
    end

    context 'with study_numbers' do
      before do
        ENV['study_numbers'] = 'ERP123,EGAS456'
        allow(process).to receive(:studies_by_accession_numbers)
      end

      it 'processes studies by accession numbers' do
        expect do
          task.invoke
        end.to output(/Processing Study Accession Numbers/).to_stdout
        expect(process).to have_received(:studies_by_accession_numbers)
          .with(%w[ERP123 EGAS456])
      end
    end
  end

  describe 'ebi:check_samples' do
    let(:task_name) { 'ebi:check_samples' }

    context 'with no arguments' do
      it 'prints usage and exits with status 1' do
        expect do
          expect do
            task.invoke
          end.to output(/Usage: bundle exec rake ebi:check_samples/).to_stdout
        end.to raise_error(SystemExit) { |e|
          expect(e.status).to eq(1)
        }
      end
    end

    context 'with study_ids' do
      before do
        ENV['study_ids'] = '123,456'
        allow(process).to receive(:samples_by_study_ids)
      end

      it 'processes samples by study IDs' do
        expect do
          task.invoke
        end.to output(/Processing Study IDs/).to_stdout
        expect(process).to have_received(:samples_by_study_ids).with(%w[123 456])
      end
    end

    context 'with sample_ids' do
      before do
        ENV['sample_ids'] = '789,1011'
        allow(process).to receive(:samples_by_ids)
      end

      it 'processes samples by sample IDs' do
        expect do
          task.invoke
        end.to output(/Processing Sample IDs/).to_stdout
        expect(process).to have_received(:samples_by_ids).with(%w[789 1011])
      end
    end

    context 'with study_numbers' do
      before do
        ENV['study_numbers'] = 'ERP123,EGAS456'
        allow(process).to receive(:samples_by_study_accession_numbers)
      end

      it 'processes samples by study accession numbers' do
        expect do
          task.invoke
        end.to output(/Processing Study Accession Numbers/).to_stdout
        expect(process).to have_received(:samples_by_study_accession_numbers)
          .with(%w[ERP123 EGAS456])
      end
    end

    context 'with sample_numbers' do
      before do
        ENV['sample_numbers'] = 'ERS123,EGAN456'
        allow(process).to receive(:samples_by_accession_numbers)
      end

      it 'processes samples by sample accession numbers' do
        expect do
          task.invoke
        end.to output(/Processing Sample Accession Numbers/).to_stdout
        expect(process).to have_received(:samples_by_accession_numbers)
          .with(%w[ERS123 EGAN456])
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength,RSpec/MultipleExpectations
