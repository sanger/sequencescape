# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Projects available at submission' do
  before do
    login_user(create(:admin, login: 'abc123', first_name: 'John', last_name: 'Doe'))
    study = create(:study, name: 'study A', state: 'pending')
    study.activate!
    visit study_information_path(study)
  end

  it 'offers the approved active project but neither the unapproved nor the pending project' do
    create(:project, name: 'Project A', approved: true)
    create(:project, name: 'Project B', approved: false)
    # Despite the feature's "inactive" wording, its step sets state to pending.
    create(:project, name: 'Project C', state: 'pending')

    click_link 'Create Submission'

    # Match the original assertion against the disabled server-rendered select;
    # choosing a template/enabling the field with JavaScript is not part of it.
    project_field = find_field('Project Name', visible: :all, disabled: true)
    expect(project_field).to have_css('option', exact_text: 'Project A')
    expect(project_field).to have_no_css('option', exact_text: 'Project B')
    expect(project_field).to have_no_css('option', exact_text: 'Project C')
  end
end
