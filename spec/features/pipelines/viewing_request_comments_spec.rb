# frozen_string_literal: true

require 'rails_helper'

describe 'Viewing request comments', :js do
  let(:user) { create :user }
  let(:pipeline) { create :sequencing_pipeline }
  let(:pipeline_name) { pipeline.name }
  let(:submission) { create :submission }
  let(:tube) { create :multiplexed_library_tube }
  let(:request) { create :sequencing_request, asset: tube, request_type: pipeline.request_types.first, submission: }

  before do
    create :comment, commentable: tube, description: 'An excellent tube'
    create :comment, commentable: tube.receptacle, description: 'A good receptacle'
    create :comment, commentable: request, description: 'A reasonable request'
  end

  it 'returns an error message' do
    login_user(user)
    visit pipeline_path(pipeline)
    within('#pending-requests') do
      expect(page).to have_text('3 comments')
      click_link('+')
      expect(page).to have_text('An excellent tube')
      expect(page).to have_text('A good receptacle')
      expect(page).to have_text('A reasonable request')
    end
  end
end
