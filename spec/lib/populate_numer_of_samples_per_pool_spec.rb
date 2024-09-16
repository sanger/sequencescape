# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'number_of_samples_per_pool:populate' do
  def run_rake_task_with_args(task_name, *args)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task("#{task_name}[#{args.join(',')}]")
  end

  shared_examples 'populating number of samples per pool' do
    it 'populates number of samples per pool' do
      submission = create(:submission)
      tube = create(:tube)
      request = create(:well_request, asset: tube, submission: submission)

      # Execute
      run_rake_task_with_args('number_of_samples_per_pool:populate', 96, submission.reload.id)

      # Verify
      expect(request.reload.request_metadata.number_of_samples_per_pool).to eq(96)
    end
  end

  context 'when all okay, populates number of samples per pool' do
    before do
      Rake.application.rake_require 'tasks/populate_number_of_samples_per_pool'
      Rake::Task.define_task(:environment)
    end

    it_behaves_like 'populating number of samples per pool'
  end
end
# rubocop:enable RSpec/DescribeClass
