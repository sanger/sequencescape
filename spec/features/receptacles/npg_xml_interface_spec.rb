# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/plain/5486734_npg_xml_interface_broken.feature
# NPG retrieves receptacle XML, so the specs compare each request property in full, including its display name.
describe 'NPG XML interface for receptacles' do
  let(:project) { create(:project, name: 'Project testing the NPG XML interface') }
  let(:study) { create(:study, name: 'Study testing the NPG XML interface') }

  def receptacle_xml(tube)
    visit receptacle_path(tube.receptacle, format: :xml)
    Hash.from_xml(page.body).fetch('asset')
  end

  def request_properties(asset_xml)
    Array.wrap(asset_xml.dig('requests', 'request', 'properties', 'property'))
  end

  # A property as parsed from the XML, built from its three fields in order
  def property(*fields)
    %w[key name value].zip(fields).to_h
  end

  it 'returns the request properties for a library tube involved in paired end sequencing' do
    tube = create(:empty_library_tube, name: 'Tube')
    create(
      :sequencing_request,
      asset: tube.receptacle,
      study: study,
      project: project,
      request_metadata_attributes: {
        customer_accepts_responsibility: false,
        read_length: 76,
        fragment_size_required_from: 1,
        fragment_size_required_to: 21
      }
    )

    asset_xml = receptacle_xml(tube)

    expect(asset_xml).to include('type' => 'LibraryTube', 'name' => 'Tube')
    expect(request_properties(asset_xml)).to contain_exactly(
                                               property('customer_accepts_responsibility', 'Still charge on fail', 'false'),
                                               property('requested_flowcell_type', 'Flowcell type', nil),
                                               property('read_length', 'Read length', '76'),
                                               property('fragment_size_required_from', 'Fragment size required (from)', '1'),
                                               property('fragment_size_required_to', 'Fragment size required (to)', '21')
                                             )
  end

  it 'returns the request properties for a sample tube involved in library creation' do
    tube = create(:sample_tube, name: 'Tube')
    create(
      :library_creation_request,
      asset: tube.receptacle,
      study: study,
      project: project,
      request_metadata_attributes: {
        customer_accepts_responsibility: false,
        read_length: 76,
        library_type: 'Standard',
        fragment_size_required_from: 1,
        fragment_size_required_to: 20
      }
    )

    asset_xml = receptacle_xml(tube)

    expect(asset_xml).to include('type' => 'SampleTube', 'name' => 'Tube')
    expect(asset_xml['sample_id']).to be_present
    expect(request_properties(asset_xml)).to contain_exactly(
                                               property('customer_accepts_responsibility', 'Still charge on fail', 'false'),
                                               property('read_length', 'Read length', '76'),
                                               property('gigabases_expected', 'Gigabases expected', nil),
                                               property('library_type', 'Library type', 'Standard'),
                                               property('fragment_size_required_from', 'Fragment size required (from)', '1'),
                                               property('fragment_size_required_to', 'Fragment size required (to)', '20')
                                             )
  end
end
