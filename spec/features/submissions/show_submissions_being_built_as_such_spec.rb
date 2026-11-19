# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Submission status messages' do
  let(:study) { create(:study, name: 'Testing submission statuses', state: 'pending') }

  before do
    login_user(create(:admin, login: 'Jon Doe', first_name: 'Jon', last_name: 'Doe',
                              email: 'Jon Doe@example.com'))
    study.activate!
  end

  def submission_in_state(state, message: nil)
    attributes = { study: study, asset_group_name: 'Faked to prevent empty asset errors' }
    attributes[:message] = message if message
    submission = FactoryHelp.submission(attributes)
    # These are display fixtures, not a test of transitions. Like the original
    # step, persist each state without triggering state-machine validation.
    submission.state = state
    submission.save!(validate: false)
    submission
  end

  {
    'building' => 'This submission is still open for editing, further orders can still be added...',
    'pending' => 'Your submission is currently pending',
    'processing' => 'Your submission is currently being processed',
    'ready' => 'Your submission has been processed'
  }.each do |state, message|
    it "displays the #{state} submission status" do
      submission = submission_in_state(state)

      visit submission_path(submission)

      expect(page).to have_text(message)
    end
  end

  it 'displays both the failed status and the recorded failure message' do
    submission = submission_in_state('failed', message: "Sorry, but it's broken")

    visit submission_path(submission)

    expect(page).to have_text('Your submission has failed')
    expect(page).to have_text("Sorry, but it's broken")
  end

  # The unknown-state outline row is commented out in the source feature.
end
