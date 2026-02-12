# frozen_string_literal: true

require 'rails_helper'
require 'ebi_check/process'

# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
describe EBICheck::Process do
  let(:buffer) { StringIO.new } # to capture output
  let(:study1_number) { 'EGA123' }
  let(:study2_number) { 'ENA456' }
  let(:process) { described_class.new(buffer) }

  let(:drop_box_url) { 'https://example.com/ena/submit/drop-box' }
  let(:ega_options) { { user: 'ega_user', password: 'ega_pw' } }
  let(:ena_options) { { user: 'ena_user', password: 'ena_pw' } }

  around do |example|
    original_drop_box_url = configatron.accession.drop_box_url!
    original_ena = configatron.accession.ena!
    original_ega = configatron.accession.ega!

    configatron.accession.drop_box_url = drop_box_url
    configatron.accession.ena = ena_options
    configatron.accession.ega = ega_options

    example.run

    configatron.accession.drop_box_url = original_drop_box_url
    configatron.accession.ena = original_ena
    configatron.accession.ega = original_ega
  end

  context 'when checking studies' do
    let(:study1) do
      create(:study, metadata_options: {
               study_ebi_accession_number: study1_number,
               study_study_title: 'Study1 Title',
               study_abstract: 'Study1 Abstract'
             })
    end
    let(:study2) do
      create(:study, metadata_options: {
               study_ebi_accession_number: study2_number,
               study_study_title: 'Study2 Title',
               study_abstract: 'Study2 Abstract'
             })
    end

    let(:study1_url) { File.join(drop_box_url, 'studies', study1_number) }
    let(:study2_url) { File.join(drop_box_url, 'studies', study2_number) }

    # Different title, description, and project_name for study1
    let(:study1_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <STUDY_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <STUDY alias="Study1_Title-sc-1" accession="EGA123">
            <DESCRIPTOR>
              <STUDY_TITLE>changed Study1_Title</STUDY_TITLE>
              <STUDY_DESCRIPTION>changed Some study on something</STUDY_DESCRIPTION>
              <CENTER_PROJECT_NAME>changed Study1_Title</CENTER_PROJECT_NAME>
              <CENTER_NAME>SC</CENTER_NAME>
              <STUDY_ABSTRACT/>
              <PROJECT_ID>old</PROJECT_ID>
              <STUDY_TYPE existing_study_type="Other" new_study_type="Not specified"/>
            </DESCRIPTOR>
          </STUDY>
        </STUDY_SET>
      XML
    end
    # Different title for study2
    let(:study2_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <STUDY_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <STUDY alias="-sc-2" accession="ENA456">
            <DESCRIPTOR>
              <STUDY_TITLE>changed Study2_Title</STUDY_TITLE>
              <STUDY_DESCRIPTION>Some study on something</STUDY_DESCRIPTION>
              <CENTER_PROJECT_NAME>Study2_Title</CENTER_PROJECT_NAME>
              <CENTER_NAME>SC</CENTER_NAME>
              <STUDY_ABSTRACT></STUDY_ABSTRACT>
              <PROJECT_ID>2</PROJECT_ID>
              <STUDY_TYPE existing_study_type="Other" new_study_type="Not specified"/>
            </DESCRIPTOR>
          </STUDY>
        </STUDY_SET>
      XML
    end

    before do
      stub_request(:get, study1_url).to_return(status: 200, body: study1_xml)
      stub_request(:get, study2_url).to_return(status: 200, body: study2_xml)
    end

    shared_examples 'checks studies' do
      it 'prints info about each study' do
        perform_action
        output = buffer.string

        expect(output).to include(
          format(described_class::TEMPLATE_STUDY_INFO, study1.id, study1.ebi_accession_number)
        )
        expect(output).to include(
          format(described_class::TEMPLATE_STUDY_INFO, study2.id, study2.ebi_accession_number)
        )
      end

      it 'prints differences for each study' do
        perform_action
        output = buffer.string

        key = :title
        sanitized_title = study1.study_metadata.study_study_title.gsub(/[^a-z\d]/i, '_')
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sanitized_title))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key, "changed #{sanitized_title}"))
        key = :description
        expect(output).to include(format(described_class::TEMPLATE_SC, key, study1.study_metadata.study_description))
        expect(output).to include(
          format(described_class::TEMPLATE_EBI, key, "changed #{study1.study_metadata.study_description}")
        )
        key = :project_name
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sanitized_title))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key, "changed #{sanitized_title}"))
        key = :title
        sanitized_title = study2.study_metadata.study_study_title.gsub(/[^a-z\d]/i, '_')
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sanitized_title))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key, "changed #{sanitized_title}"))
      end
    end

    describe '#studies_by_ids' do
      let(:perform_action) { process.studies_by_ids([study1.id, study2.id]) }

      it_behaves_like 'checks studies'
    end

    describe '#studies_by_accession_numbers' do
      let(:perform_action) do
        process.studies_by_accession_numbers([study1.ebi_accession_number, study2.ebi_accession_number])
      end

      it_behaves_like 'checks studies'
    end
  end

  context 'when checking samples', :accessioning_enabled do
    let(:sample1_number) { 'EGAS12345678901' }
    let(:sample2_number) { 'ERS98765432' }
    let(:sample1) do
      create(:sample_for_accessioning,
             sample_metadata: create(:sample_metadata_with_accession_number,
                                     sample_ebi_accession_number: sample1_number))
    end
    let(:sample2) do
      create(:sample_for_accessioning,
             sample_metadata: create(:sample_metadata_with_accession_number,
                                     sample_ebi_accession_number: sample2_number))
    end
    let(:study1) do
      create(:study, enforce_accessioning: true, metadata_options: {
               data_release_strategy: Study::DATA_RELEASE_STRATEGY_OPEN,
               study_ebi_accession_number: study1_number
             })
    end
    let(:study2) do
      create(:study, enforce_accessioning: true, metadata_options: {
               data_release_strategy: Study::DATA_RELEASE_STRATEGY_OPEN,
               study_ebi_accession_number: study2_number
             })
    end

    # Different sample description and gender for sample1
    let(:sample1_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <SAMPLE_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <SAMPLE accession="EGAS12345678901">
            <TITLE>Sample Public Name</TITLE>
            <SAMPLE_NAME>
              <COMMON_NAME>A common name</COMMON_NAME>
              <TAXON_ID>1</TAXON_ID>
            </SAMPLE_NAME>
            <SAMPLE_ATTRIBUTES>
              <SAMPLE_ATTRIBUTE>
                <TAG>strain</TAG>
                <VALUE/>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>sample description</TAG>
                <VALUE>changed </VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>gender</TAG>
                <VALUE>changed unknown</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>phenotype</TAG>
                <VALUE>Indescribable</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>subject id</TAG>
                <VALUE>1</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>geographic location (country and/or sea)</TAG>
                <VALUE>changed Australia</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>collection date</TAG>
                <VALUE>2000-01-01T00:00</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Phenotype</TAG>
                <VALUE>Indescribable</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Sex</TAG>
                <VALUE>unknown</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-DiseaseState</TAG>
                <VALUE>Awful</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-GrowthCondition</TAG>
                <VALUE>No</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Species</TAG>
                <VALUE>A common name</VALUE>
              </SAMPLE_ATTRIBUTE>
            </SAMPLE_ATTRIBUTES>
          </SAMPLE>
        </SAMPLE_SET>
      XML
    end

    # Different geographic location (country and/or sea) for sample2
    let(:sample2_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <SAMPLE_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <SAMPLE accession="ERS98765432">
            <TITLE>Sample Public Name</TITLE>
            <SAMPLE_NAME>
              <COMMON_NAME>A common name</COMMON_NAME>
              <TAXON_ID>1</TAXON_ID>
            </SAMPLE_NAME>
            <SAMPLE_ATTRIBUTES>
              <SAMPLE_ATTRIBUTE>
                <TAG>strain</TAG>
                <VALUE/>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>sample description</TAG>
                <VALUE/>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>gender</TAG>
                <VALUE>unknown</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>phenotype</TAG>
                <VALUE>Indescribable</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>subject id</TAG>
                <VALUE>1</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>geographic location (country and/or sea)</TAG>
                <VALUE>changed not provided</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>collection date</TAG>
                <VALUE>2000-01-01T00:00</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Phenotype</TAG>
                <VALUE>Indescribable</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Sex</TAG>
                <VALUE>unknown</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-DiseaseState</TAG>
                <VALUE>Awful</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-GrowthCondition</TAG>
                <VALUE>No</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Species</TAG>
                <VALUE>A common name</VALUE>
              </SAMPLE_ATTRIBUTE>
            </SAMPLE_ATTRIBUTES>
          </SAMPLE>
        </SAMPLE_SET>
      XML
    end

    let(:sample1_url) { File.join(drop_box_url, 'samples', sample1_number) }
    let(:sample2_url) { File.join(drop_box_url, 'samples', sample2_number) }

    before do
      create(:insdc_country, name: 'Australia')
      create(:study_sample, study: study1, sample: sample1)
      create(:study_sample, study: study2, sample: sample2)
      stub_request(:get, sample1_url).to_return(status: 200, body: sample1_xml)
      stub_request(:get, sample2_url).to_return(status: 200, body: sample2_xml)
    end

    shared_examples 'checks samples' do
      it 'prints info about study of each sample' do
        perform_action
        output = buffer.string

        expect(output).to include(
          format(described_class::TEMPLATE_STUDY_INFO, study1.id, study1.ebi_accession_number)
        )
        expect(output).to include(
          format(described_class::TEMPLATE_STUDY_INFO, study2.id, study2.ebi_accession_number)
        )
      end

      it 'prints info about each sample' do
        perform_action
        output = buffer.string

        expect(output).to include(
          format(described_class::TEMPLATE_SAMPLE_INFO, sample1.id, sample1.ebi_accession_number)
        )
        expect(output).to include(
          format(described_class::TEMPLATE_SAMPLE_INFO, sample2.id, sample2.ebi_accession_number)
        )
      end

      it 'prints differences for each sample' do
        perform_action
        output = buffer.string

        key = :'sample description'
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sample1.sample_metadata.sample_description))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key,
                                         "changed #{sample1.sample_metadata.sample_description}"))

        key = :gender
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sample1.sample_metadata.gender.downcase))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key,
                                         "changed #{sample1.sample_metadata.gender.downcase}"))

        key = :'geographic location (country and/or sea)'
        expect(output).to include(format(described_class::TEMPLATE_SC, key, sample2.sample_metadata.country_of_origin))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key,
                                         "changed #{sample2.sample_metadata.country_of_origin}"))

        # Value defined in EBI, but not locally
        key = :'sample description'
        expect(output).to include(format(described_class::TEMPLATE_SC, key, '<missing>'))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key,
                                         'changed'))

        # Value defined locally, but not in EBI
        key = :'arrayexpress-growth_condition'
        expect(output).to include(format(described_class::TEMPLATE_SC, key, 'No'))
        expect(output).to include(format(described_class::TEMPLATE_EBI, key,
                                         '<missing>'))
      end
    end

    describe '#samples_by_ids' do
      let(:perform_action) { process.samples_by_ids([sample1.id, sample2.id]) }

      it_behaves_like 'checks samples'
    end

    describe '#samples_by_accession_numbers' do
      let(:perform_action) do
        process.samples_by_accession_numbers([sample1.ebi_accession_number, sample2.ebi_accession_number])
      end

      it_behaves_like 'checks samples'
    end

    describe '#samples_by_study_ids' do
      let(:perform_action) { process.samples_by_study_ids([study1.id, study2.id]) }

      it_behaves_like 'checks samples'
    end

    describe '#samples_by_study_accession_numbers' do
      let(:perform_action) do
        process.samples_by_study_accession_numbers([study1.ebi_accession_number, study2.ebi_accession_number])
      end

      it_behaves_like 'checks samples'
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
