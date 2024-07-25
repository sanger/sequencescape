# frozen_string_literal: true

require 'rails_helper'

# only load Rake tasks if they haven't been loaded already
Rails.application.load_tasks if Rake::Task.tasks.empty?

describe 'support:disable_hiseq_submission_templates', type: :task do
  let(:task_invoke) { Rake::Task[self.class.top_level_description].invoke }

  context 'when the disable_hiseq_submission_templates task is invoked' do
    it 'updates all hiseq submissions to have a superceded_by_id of -2' do
      # Create unused submission templates
      create_list(:submission_template, 5)
      (1..5).each do |i|
        # Create HiSeq submission templates
        create(:submission_template, name: "HiSeq #{i}")
        # Create alternate name HiSeq submission templates
        create(:submission_template, name: "Some other hiseq #{i}")
      end

      expect { task_invoke }.to output(<<~HEREDOC).to_stdout
          Disabled 10 HiSeq submission templates.
        HEREDOC
      # Expect all hiseq submissions to have a superceded_by_id of -2
      expect(SubmissionTemplate.where('name LIKE ?', '%hiseq%').all? { |st| st.superceded_by_id == -2 }).to be true
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
      end

      expect { Rake::Task['support:enable_hiseq_submission_templates'].invoke }.to output(<<~HEREDOC).to_stdout
          Enabled 10 HiSeq submission templates.
        HEREDOC
      # Expect all hiseq submissions to have a superceded_by_id of -1
      expect(SubmissionTemplate.where('name LIKE ?', '%hiseq%').all? { |st| st.superceded_by_id == -1 }).to be true
    end
  end
end
