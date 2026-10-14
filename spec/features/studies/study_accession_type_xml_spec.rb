# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/5549125_add_OTHER_study_type_to_EBI.feature
RSpec.describe 'Study accession XML study type' do
  # Study types the EBI recognises (StudyType#valid_type is true)
  ebi_study_types = [
    'Synthetic Genomics',
    'Forensic or Paleo-genomics',
    'Gene Regulation Study',
    'Cancer Genomics',
    'Whole Genome Sequencing',
    'Metagenomics',
    'Transcriptome Analysis',
    'Population Genomics',
    'Resequencing',
    'Epigenetics'
  ]

  # Study types the EBI doesn't recognise (StudyType#valid_type is false), which are sent as 'Other'
  non_ebi_study_types = ['Exome Sequencing', 'Pooled Clone Sequencing', 'TraDIS']

  let!(:study) { create(:study, name: 'My study') }

  def study_type_node_for(study_type)
    study.study_metadata.update!(study_type:)
    page.driver.get(study_show_accession_path(study), {}, 'HTTP_ACCEPT' => 'application/xml')
    Nokogiri::XML(page.source).at_xpath('//STUDY_TYPE')
  end

  ebi_study_types.each do |name|
    it "uses the '#{name}' study type as is" do
      node = study_type_node_for(create(:study_type, name: name, valid_type: true))

      expect(node['existing_study_type']).to eq(name)
    end
  end

  non_ebi_study_types.each do |name|
    it "sends '#{name}' as a new study type with an existing type of 'Other'" do
      node = study_type_node_for(create(:study_type, name: name, valid_type: false))

      expect(node['existing_study_type']).to eq('Other')
      expect(node['new_study_type']).to eq(name)
    end
  end
end
