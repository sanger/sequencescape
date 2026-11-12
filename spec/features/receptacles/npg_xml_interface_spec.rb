# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/plain/5486734_npg_xml_interface_broken.feature
# NPG retrieves receptacle XML. The important thing to check is that the property 'key' elements exist.
describe 'NPG XML interface for receptacles' do
  let(:project) { create(:project, name: 'Project testing the NPG XML interface') }
  let(:study) { create(:study, name: 'Study testing the NPG XML interface') }

  def receptacle_xml(tube)
    visit receptacle_path(tube.receptacle, format: :xml)
    Hash.from_xml(page.body).fetch('asset')
  end

  def property_keys(asset_xml)
    Array.wrap(asset_xml.dig('requests', 'request', 'properties', 'property')).pluck('key')
  end

  it 'returns the request properties for a library tube involved in paired end sequencing' do
    tube = create(:empty_library_tube, name: 'Tube')
    create(:sequencing_request, asset: tube.receptacle, study: study, project: project)

    asset_xml = receptacle_xml(tube)

    expect(asset_xml).to include('type' => 'LibraryTube', 'name' => 'Tube')
    expect(property_keys(asset_xml)).to include(
      'customer_accepts_responsibility',
      'requested_flowcell_type',
      'read_length',
      'fragment_size_required_from',
      'fragment_size_required_to'
    )
  end

  it 'returns the request properties for a sample tube involved in library creation' do
    tube = create(:sample_tube, name: 'Tube')
    create(:library_creation_request, asset: tube.receptacle, study: study, project: project)

    asset_xml = receptacle_xml(tube)

    expect(asset_xml).to include('type' => 'SampleTube', 'name' => 'Tube')
    expect(asset_xml['sample_id']).to be_present
    expect(property_keys(asset_xml)).to include(
      'customer_accepts_responsibility',
      'read_length',
      'gigabases_expected',
      'library_type',
      'fragment_size_required_from',
      'fragment_size_required_to'
    )
  end
end
