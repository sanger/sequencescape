# frozen_string_literal: true

require 'rails_helper'

# only load Rake tasks if they haven't been loaded already
Rails.application.load_tasks if Rake::Task.tasks.empty?

describe 'support:disable_hiseq_submission_templates', type: :task do
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

      Rake::Task['support:disable_hiseq_submission_templates'].invoke

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

  context 'when the enable_hiseq_submission_templates task is invoked' do
    it 'updates all hiseq submissions to have a superceded_by_id of -1' do
      # Create unused submission templates
      create_list(:submission_template, 5)
      (1..5).each do |i|
        # Create HiSeq submission templates
        create(:submission_template, name: "HiSeq #{i}", superceded_by_id: -2)
        # Create alternate name HiSeq submission templates
        create(:submission_template, name: "Some other hiseq #{i}", superceded_by_id: -2)
        # Create superceded HiSeq submission templates that should not be restored (already superceded)
        create(:submission_template, name: "Superceded HiSeq #{i}", superceded_by_id: 5)
      end

      allow(Rails.logger).to receive(:info)

      Rake::Task['support:enable_hiseq_submission_templates'].invoke

      expect(Rails.logger).to have_received(:info).with('Enabled 10 HiSeq submission templates.').at_least(:once)
      # Expect all hiseq submissions to have a superceded_by_id of -1
      expect(SubmissionTemplate.where('name LIKE ?', '%hiseq%').count { |st| st.superceded_by_id == -1 }).to eq(10)
      # Expect all pre-existing superceded hiseq submissions to have not been updated
      expect(
        SubmissionTemplate.where('name LIKE ?', '%superceded hiseq%').count { |st| st.superceded_by_id == 5 }
      ).to eq(5)
    end
  end
end
