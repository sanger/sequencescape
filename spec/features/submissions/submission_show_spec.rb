# frozen_string_literal: true

require 'rails_helper'

describe 'Submission show' do
  let(:user) { create(:admin, login: 'user') }
  let(:template) { create(:submission_template) }
  let(:study) { create(:study, name: 'abc123_study') }
  let(:project) { create(:project, name: 'Test project') }
  let(:submission) do
    order = create(:order_with_submission, template_name: template.name, study: study, project: project,
                                           asset_group: create(:asset_group, study:))
    order.submission
  end

  before do
    login_user user
    visit submission_path(id: submission.id)
  end

  describe 'has the correct content' do
    it 'shows the submission information' do
      expect(page).to have_content("Submission #{submission.id} - #{template.name}")
      expect(page).to have_content("Project #{project.name}")
      expect(page).to have_content("Study #{study.name}")
    end

    it 'shows the correct sidebar links' do
      expect(page).to have_link('Print labels for')
      expect(page).to have_link('Submissions Inbox')
      # This should only be visible for submissions with the correct scRNA template
      expect(page).to have_no_link('Download scRNA Core cDNA pooling plan')
    end
  end

  describe 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p submissions' do
    let(:template) { create(:submission_template, name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p') }

    it 'shows the correct sidebar links' do
      expect(page).to have_link('Download scRNA Core cDNA pooling plan')
    end

    it 'downloads the correct pooling plan' do
      click_link 'Download scRNA Core cDNA pooling plan'
      expect(page.response_headers['Content-Disposition']).to include(
        "#{submission.id}_scrna_core_cdna_pooling_plan.csv"
      )
    end
  end
end
