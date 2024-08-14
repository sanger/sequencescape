# frozen_string_literal: true

require 'rails_helper'

describe 'support:disable_hiseq_submission_templates', type: :task do
  let(:load_tasks) { Rails.application.load_tasks }
  let(:task_reenable) { Rake::Task[self.class.top_level_description].reenable }
  let(:task_invoke) { Rake::Task[self.class.top_level_description].invoke }

  before do
    load_tasks # Load tasks directly in the test to avoid intermittent CI failures
    task_reenable # Allows the task to be invoked again
  end

  context 'when the disable_hiseq_submission_templates task is invoked' do
    it 'updates all hiseq submissions to have a superceded_by_id of -2' do
      # Create unused submission templates
      create_list(:submission_template, 5)
      (1..5).each do |i|
        # Create HiSeq submission templates
        create(:submission_template, name: "HiSeq #{i}")
        # Create alternate name HiSeq submission templates
        create(:submission_template, name: "Some other hiseq #{i}")
        # Create superceded HiSeq submission templates that should not be updated (already superceded)
        create(:submission_template, name: "Superceded HiSeq #{i}", superceded_by_id: 5)
      end

      allow(Rails.logger).to receive(:info)

      task_invoke

      expect(Rails.logger).to have_received(:info).with('Disabled 10 HiSeq submission templates.').at_least(:once)
      # Expect all hiseq submissions to have a superceded_by_id of -2
      expect(SubmissionTemplate.where('name LIKE ?', '%hiseq%').count { |st| st.superceded_by_id == -2 }).to eq(10)
      # Expect all pre-existing superceded hiseq submissions to have not been updated
      expect(
        SubmissionTemplate.where('name LIKE ?', '%superceded hiseq%').count { |st| st.superceded_by_id == 5 }
      ).to eq(5)
      # Expect all other submissions to have a superceded_by_id of -1
      expect(SubmissionTemplate.where('name NOT LIKE ?', '%hiseq%').all? { |st| st.superceded_by_id == -1 }).to be true
    end
  end
end
