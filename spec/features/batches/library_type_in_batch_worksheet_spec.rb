# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/ss507_library_type_in_batch_worksheet.feature
describe 'Library type in the batch worksheet' do
  let(:user) { create(:admin, login: 'me') }

  # Equivalent of the seeded 'Cluster formation PE (spiked in controls)' pipeline
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow, name: 'Cluster formation PE (spiked in controls)') }
  let(:batch) do
    create(:sequencing_batch, pipeline: pipeline, request_count: 8, user: user,
                              request_factory: :request_with_sequencing_request_type)
  end

  it 'shows the library types of the batch requests' do
    login_user(user)
    visit batch_path(batch)
    click_link 'Print worksheet'

    expect(page).to have_text('Library Types')
    expect(page).to have_text('Standard')
  end
end
