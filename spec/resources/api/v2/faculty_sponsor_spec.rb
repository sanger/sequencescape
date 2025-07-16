# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/faculty_sponsor_resource'

RSpec.describe Api::V2::FacultySponsorResource, type: :resource do
  subject(:resource) { described_class.new(faculty_sponsor, {}) }

  let(:faculty_sponsor) { create(:faculty_sponsor) }

  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :name
  end
end
