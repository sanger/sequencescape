# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

describe 'Viewing a receptacle' do
  let(:user) { create(:user) }

  shared_examples 'a receptacle' do
    it 'can be viewed on its show page' do
      login_user user
      visit receptacle_path(receptacle)
      expect(find('h1')).to have_content("Receptacle #{receptacle.display_name}")
    end
  end

  context 'with a sample tube' do
    let(:receptacle) { create(:sample_tube).receptacle }

    it_behaves_like 'a receptacle'
  end

  context 'with a library_tube' do
    let(:receptacle) { create(:library_tube).receptacle }

    it_behaves_like 'a receptacle'
  end

  context 'with a lane' do
    let(:receptacle) { create(:lane) }

    it_behaves_like 'a receptacle'
  end

  context 'with a well' do
    let(:receptacle) { create(:well) }

    it_behaves_like 'a receptacle'
  end
end
