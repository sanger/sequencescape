# frozen_string_literal: true

require 'rails_helper'
require 'ebi_check/utils'

RSpec.describe EbiCheck::Utils do
  describe '.extract_study_fields' do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <STUDY_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <STUDY alias="Human_Genetic_Interactions_-sc-7255" accession="ERP145898">
            <DESCRIPTOR>
              <STUDY_TITLE>Human_Genetic_Interactions_</STUDY_TITLE>
              <STUDY_DESCRIPTION>Dual gene knockout using CRISPR to study human genetic interactions.</STUDY_DESCRIPTION>
              <CENTER_PROJECT_NAME>Human_Genetic_Interactions_</CENTER_PROJECT_NAME>
              <CENTER_NAME>SC</CENTER_NAME>
              <STUDY_ABSTRACT>R&amp;D project to see genetic interaction across human genome.</STUDY_ABSTRACT>
              <PROJECT_ID>7255</PROJECT_ID>
              <STUDY_TYPE existing_study_type="Other" new_study_type="Amplicon"/>
            </DESCRIPTOR>
            <STUDY_ATTRIBUTES>
              <STUDY_ATTRIBUTE>
                <TAG>arrayexpress</TAG>
                <VALUE/>
              </STUDY_ATTRIBUTE>
            </STUDY_ATTRIBUTES>
          </STUDY>
        </STUDY_SET>
      XML
    end

    it 'extracts study title' do
      result = described_class.extract_study_fields(xml)
      expect(result[:title]).to eq('Human_Genetic_Interactions_')
    end

    it 'extracts study description' do
      result = described_class.extract_study_fields(xml)
      expect(result[:description]).to eq('Dual gene knockout using CRISPR to study human genetic interactions.')
    end

    it 'extracts center project name' do
      result = described_class.extract_study_fields(xml)
      expect(result[:project_name]).to eq('Human_Genetic_Interactions_')
    end

    it 'extracts study abstract' do
      result = described_class.extract_study_fields(xml)
      expect(result[:abstract]).to eq('R&D project to see genetic interaction across human genome.')
    end

    it 'extracts existing study type' do
      result = described_class.extract_study_fields(xml)
      expect(result[:existing_study_type]).to eq('Other')
    end

    it 'extracts new study type' do
      result = described_class.extract_study_fields(xml)
      expect(result[:new_study_type]).to eq('Amplicon')
    end
  end

  describe '.extract_sample_fields' do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <SAMPLE_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <SAMPLE accession="ERS23018915">
            <TITLE>296-COLO2-10X_rep3</TITLE>
            <SAMPLE_NAME>
              <COMMON_NAME>Homo sapiens</COMMON_NAME>
              <TAXON_ID>9606</TAXON_ID>
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
                <VALUE/>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>phenotype</TAG>
                <VALUE>Cell Line</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>subject id</TAG>
                <VALUE>296-COLO2-10X_rep3</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>geographic location (country and/or sea)</TAG>
                <VALUE>not provided</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>collection date</TAG>
                <VALUE>2025-01-29</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Phenotype</TAG>
                <VALUE>Cell Line</VALUE>
              </SAMPLE_ATTRIBUTE>
              <SAMPLE_ATTRIBUTE>
                <TAG>ArrayExpress-Species</TAG>
                <VALUE>Homo sapiens</VALUE>
              </SAMPLE_ATTRIBUTE>
            </SAMPLE_ATTRIBUTES>
          </SAMPLE>
        </SAMPLE_SET>
      XML
    end

    it 'extracts sample title' do
      result = described_class.extract_sample_fields(xml)
      expect(result[:title]).to eq('296-COLO2-10X_rep3')
    end

    it 'extracts sample common name' do
      result = described_class.extract_sample_fields(xml)
      expect(result[:common_name]).to eq('Homo sapiens')
    end

    it 'extracts sample taxon id' do
      result = described_class.extract_sample_fields(xml)
      expect(result[:taxon_id]).to eq('9606')
    end

    it 'extracts sample attributes' do
      result = described_class.extract_sample_fields(xml)
      expect(result).to include(
        strain: '',
        'sample description': '',
        gender: '',
        phenotype: 'Cell Line',
        title: '296-COLO2-10X_rep3',
        'geographic location (country and/or sea)': 'not provided',
        'collection date': '2025-01-29',
        'arrayexpress-phenotype': 'Cell Line',
        'arrayexpress-species': 'Homo sapiens'
      )
    end
  end
end
