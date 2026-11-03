# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Study XML view', type: :request do
  let(:user) { create(:user, email: 'login@example.com', password: 'password') }
  let(:owner) { create(:user, login: 'owner', first_name: 'I am', last_name: 'The Owner') }
  let(:manager) { create(:user, login: 'manager', first_name: 'I am', last_name: 'The Manager') }

  let(:expected_xml) do
    Rails.root.join('spec/data/studies/study.xml').read
  end

  let(:study) do
    create(
      :study,
      name: 'Study for XML',
      metadata_options: {
        data_access_group: 'group1',
        contaminated_human_dna: 'Yes',
        remove_x_and_autosomes: 'Yes',
        commercially_available: 'No',
        faculty_sponsor: create(:faculty_sponsor, name: 'Jack Sponsor'),
        reference_genome: ReferenceGenome.find_or_create_by!(name: 'RefGenome'),
        program: Program.find_or_create_by!(name: 'General')
      }
    )
  end

  before do
    travel_to(Time.zone.parse('2010-Oct-03 18:21:11+01:00'))
    create(:admin)
    owner.grant_role('owner', study)
    manager.grant_role('manager', study)
    post '/login', params: { login: user.login, password: 'password' }
  end

  it 'returns the expected study XML' do
    get study_path(study, format: :xml)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/xml')

    expected = normalize_xml(expected_xml)
    received = normalize_xml(response.body)
    expect(received).to eq(expected)
  end

  private

  def normalize_xml(xml)
    data = Hash.from_xml(xml)
    # The original comparison treats missing and empty descriptor values alike.
    data.fetch('study').fetch('descriptors').fetch('descriptor').each do |descriptor|
      descriptor.reverse_merge!('value' => nil)
    end
    normalize_xml_data(data)
  end

  # Preserve the original feature's ignored IDs and order-independent comparison.
  def normalize_xml_data(data)
    case data
    when Hash
      data.except('id', 'user_id').sort.to_h.transform_values { |value| normalize_xml_data(value) }
    when Array
      data.map { |value| normalize_xml_data(value) }.sort_by(&:to_a)
    else
      data
    end
  end
end
