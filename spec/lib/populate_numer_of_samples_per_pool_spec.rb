# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'number_of_samples_per_pool:populate' do
  def run_rake_task_with_args(task_name, *args)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task("#{task_name}[#{args.join(',')}]")
  end

  context 'when number of samples per pool rake task is invoked' do
    before do
      Rake.application.rake_require 'tasks/populate_number_of_samples_per_pool'
      Rake::Task.define_task(:environment)
    end

    it 'populating number of samples per pool' do
      submission = create(:submission)
      tube = create(:tube)
      request = create(:well_request, asset: tube, submission: submission)

      # Execute
      run_rake_task_with_args('number_of_samples_per_pool:populate', 20, submission.reload.id)

      # Verify
      expect(request.reload.request_metadata.number_of_samples_per_pool).to eq(20)
    end

    it 'does not populate number of samples per pool when submission_id is nil' do
      error_message = nil

      # Execute
      begin
        run_rake_task_with_args('number_of_samples_per_pool:populate', 20, nil)
      rescue StandardError => e
        error_message = e.message
      end

      # Verify
      expect(error_message).to eq('Please provide a submission_id to populate the number of samples per pool column.')
    end

    it 'does not populate number of samples per pool when samples_per_pool is nil' do
      submission = create(:submission)
      create(:tube)
      error_message = nil

      # Execute
      begin
        run_rake_task_with_args('number_of_samples_per_pool:populate', nil, submission.reload.id)
      rescue StandardError => e
        error_message = e.message
      end

      # Verify
      expect(error_message).to
      eq('Please provide the number of samples per pool to populate in request_metadata table.')
    end
  end
end
# rubocop:enable RSpec/DescribeClass
