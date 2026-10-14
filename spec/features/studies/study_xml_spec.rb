# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/4295391_study_xml_needs_to_be_reverted_to_old_version.feature
#
# Checks the XML served for a study ({StudiesController#show}) hasn't changed from the original API format.
RSpec.describe 'Study XML' do
  # Elements whose values depend on database ids, which are not stable between test runs.
  let(:unstable_elements) { /\A(?:id|user_id|family_id)\z/ }
  let(:frozen_time) { Time.zone.parse('2010-Oct-03 18:21:11+01:00') }
  let(:owner) { create(:user, login: 'owner', first_name: 'I am', last_name: 'The Owner') }
  let(:manager) { create(:user, login: 'manager', first_name: 'I am', last_name: 'The Manager') }

  let(:study) do
    create(
      :study,
      name: 'Study for XML',
      state: 'active',
      metadata_options: {
        faculty_sponsor: create(:faculty_sponsor, name: 'Jack Sponsor'),
        contaminated_human_dna: Study::YES,
        remove_x_and_autosomes: Study::YES,
        commercially_available: Study::NO,
        data_access_group: 'group1',
        reference_genome: create(:reference_genome, name: 'RefGenome')
      }
    )
  end

  # Decodes the XML into a hash, dropping the unstable elements and ordering arrays so the comparison doesn't depend on
  # the order of repeated elements.
  def normalise(data)
    case data
    when Hash
      kept = data.reject { |name, _| name.match?(unstable_elements) }
      kept.transform_values { |value| normalise(value) }
    when Array
      data.map { |element| normalise(element) }.sort_by(&:to_s)
    else
      data
    end
  end

  before do
    travel_to(frozen_time)
    create(:admin)
    owner.grant_role('owner', study)
    manager.grant_role('manager', study)
  end

  it 'returns the expected XML for a study' do
    page.driver.get(study_path(study), {}, 'HTTP_ACCEPT' => 'application/xml')

    expect(normalise(Hash.from_xml(page.source))).to eq(
      normalise(Hash.from_xml(expected_xml))
    )
  end

  def expected_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <study api_version="0.6">
        <id>740</id>
        <name>Study for XML</name>
        <active>true</active>
        <user_id>2230</user_id>
        <managers>
          <manager>
            <login>manager</login>
            <email>manager@example.com</email>
            <name>I am The Manager</name>
            <id>2229</id>
          </manager>
        </managers>
        <owners>
          <owner>
            <login>owner</login>
            <email>owner@example.com</email>
            <name>I am The Owner</name>
            <id>2228</id>
          </owner>
        </owners>
        <!-- Family has been deprecated -->
        <family_id></family_id>
        <created_at>2010-10-03 18:21:11 +0100</created_at>
        <updated_at>2010-10-03 18:21:11 +0100</updated_at>
        <descriptors>
          <descriptor>
            <name>Number of gigabases per sample (minimum 0.15)</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Prelim ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Program</name>
            <value>General</value>
          </descriptor>
          <descriptor>
            <name>Reason for delaying release</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?</name>
            <value>Yes</value>
          </descriptor>
          <descriptor>
            <name>Does this study require y chromosome data to be separated from x and autosomal data before archival?</name>
            <value>false</value>
          </descriptor>
          <descriptor>
            <name>Does this study require the removal of X chromosome and autosome sequence?</name>
            <value>Yes</value>
          </descriptor>
          <descriptor>
            <name>What sort of study is this?</name>
            <value>genomic sequencing</value>
          </descriptor>
          <descriptor>
            <name>What is the reason for preventing data release?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Will you be using WTSI's standard access agreement?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Reference Genome</name>
            <value>RefGenome</value>
          </descriptor>
          <descriptor>
            <name>Study Visibility</name>
            <value>Hold</value>
          </descriptor>
          <descriptor>
            <name>ENA Study Accession Number</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Study name abbreviation</name>
            <value>WTCCC</value>
          </descriptor>
          <descriptor>
            <name>Study Type</name>
            <value>Not specified</value>
          </descriptor>
          <descriptor>
            <name>If reason for exemption requires DAC approval, what is the approval number?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Delay for</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Title</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Comment regarding prevention of data release and approval</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>How is the data release to be timed?</name>
            <value>standard</value>
          </descriptor>
          <descriptor>
            <name>Abstract</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Study description</name>
            <value>Some study on something</value>
          </descriptor>
          <descriptor>
            <name>Alignments in BAM</name>
            <value>true</value>
          </descriptor>
          <descriptor>
          <name>Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?</name>
          <value>No</value>
          </descriptor>
          <descriptor>
            <name>ENA Project ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Comment regarding data release timing and approval</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>What is the data release strategy for this study?</name>
            <value>open</value>
          </descriptor>
          <descriptor>
            <name>Do any of the samples in this study contain human DNA?</name>
            <value>No</value>
          </descriptor>
          <descriptor>
            <name>Faculty Sponsor</name>
            <value>Jack Sponsor</value>
          </descriptor>
          <descriptor>
            <name>Please explain the reason for delaying release</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Please explain the reason for preventing data release</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>SNP parent study ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>SNP study ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>HuMFre approval number</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>S3 email list</name>
            <value>aa1@sanger.ac.uk;aa2@sanger.ac.uk</value>
          </descriptor>
          <descriptor>
            <name>Data deletion period</name>
            <value>3 months</value>
          </descriptor>
          <descriptor><name>Contaminated Human Data Access Group</name><value></value></descriptor>
          <descriptor><name>Data access group</name><value>group1</value></descriptor>
          <descriptor><name>EBI Library Selection</name><value>PCR</value></descriptor>
          <descriptor><name>EBI Library Source</name><value>GENOMIC</value></descriptor>
          <descriptor><name>EBI Library Strategy</name><value>WGS</value></descriptor>
          <descriptor><name>EGA DAC Accession Number</name></descriptor>
          <descriptor><name>EGA Policy Accession Number</name></descriptor>
          <descriptor><name>Policy Url</name></descriptor>
          <descriptor><name>Policy title</name></descriptor>
          <descriptor><name>ArrayExpress Accession Number</name></descriptor>
          <descriptor><name>When do you anticipate sharing the data?</name><value></value></descriptor>
          <descriptor><name>Are you planning to share the data as part of a preprint?</name></descriptor>
        </descriptors>
      </study>
    XML
  end
end
