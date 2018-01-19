# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::StudiesController, type: :request, aker: true do
  let!(:user_1) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:study_1) do
    create(:study).tap do |s|
      create(:role, users: [user_1], name: 'manager', authorizable_type: 'Study', authorizable_id: s.id)
    end
  end
  let!(:study_2) do
    create(:study).tap do |s|
      create(:role, users: [user_1], name: 'owner', authorizable_type: 'Study', authorizable_id: s.id)
    end
  end
  let!(:study_3) do
    create(:study).tap do |s|
      create(:role, users: [user_1], name: 'follower', authorizable_type: 'Study', authorizable_id: s.id)
    end
  end
  let!(:study_4) do
    create(:study).tap do |s|
      create(:role, users: [user_2], name: 'follower', authorizable_type: 'Study', authorizable_id: s.id)
    end
  end
  let!(:study_5) do
    create(:study_for_study_list_inactive).tap do |s|
      create(:role, users: [user_1], name: 'follower', authorizable_type: 'Study', authorizable_id: s.id)
    end
  end
  it 'study scope returns correct studies' do
    studies = Study.by_state('active').by_user(user_1.login)
    expect(studies.count).to eq(3)
    expect(studies).to include(study_1)
    expect(studies).to include(study_2)
    expect(studies).to include(study_3)
  end

  it 'api request returns the correct studies' do
    get api_v2_studies_path, params: { "filter[state]": 'active', "filter[user]": user_1.login }
    expect(response).to be_success
    json = ActiveSupport::JSON.decode(response.body)
    expect(json['data'].length).to eq(3)
    study = json['data'].first['attributes']
    expect(study).to include('name')
    expect(study).to include('uuid')
  end
end
