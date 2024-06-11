# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

describe 'Viewing an asset' do
  # We'll keep the old controller around for a little while to ensure any
  # bookmarks continue to work.

  let(:user) { create(:user) }

  before do
    expect(Labware).to receive(:find_by).with(id: '1').and_return(labware)
    expect(Receptacle).to receive(:find_by).with(id: '1').and_return(receptacle)
    login_user user
    visit asset_path(id: 1)
  end

  context 'when the id is unambiguous' do
    let(:labware) { create(:sample_tube) }
    let(:receptacle) { nil }

    it 'redirects to the Labware' do
      expect(find('h1')).to have_content("Labware #{labware.name}")
    end
  end

  context 'when the receptacle maps to the labware' do
    let(:labware) { create(:sample_tube) }
    let(:receptacle) { labware.receptacle }

    it 'redirects to the Receptacle' do
      expect(find('h1')).to have_content("Receptacle #{labware.name}")
    end
  end

  context 'when there is some ambiguity' do
    let(:labware) { create(:sample_tube) }
    let(:receptacle) { create(:sample_tube).receptacle }

    it 'redirects to the Labware' do
      expect(find('h1')).to have_content('Which Did You Mean?')
    end
  end
end
