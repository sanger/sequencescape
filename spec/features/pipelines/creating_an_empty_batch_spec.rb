# frozen_string_literal: true

require 'rails_helper'

describe 'Empty batch creation', :js do
  let(:user) { create(:user) }
  let(:pipeline) { create(:cherrypick_pipeline) }
  let(:pipeline_name) { pipeline.name }
  let(:submission) { create(:submission) }
  let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, 1, sample_count: 2) }
  let(:request_type) { pipeline.request_types.first }

  before do
    plates.each do |plate|
      plate.wells.each do |well|
        # create the requests for cherrypicking
        create(:cherrypick_request, asset: well, request_type: request_type, submission: submission)
      end
    end
  end

  it 'returns an error message' do
    login_user(user)
    visit pipeline_path(pipeline)
    click_on 'Submit', above: find('table#pipeline_inbox')
    expect(page).to have_content 'Batches must contain at least one request'
  end
end
