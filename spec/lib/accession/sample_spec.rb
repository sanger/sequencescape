# frozen_string_literal: true

require 'rails_helper'

COUNTRY_TAG = 'geographic location (country and/or sea)'
COLLECTION_DATE_TAG = 'collection date'

def find_value_at_tag(xml_received, tag_name)
  xml = Nokogiri::XML::Document.parse(xml_received)
  xml
    .at('SAMPLE_ATTRIBUTES')
    .children
    .each do |elem|
      return elem.search('VALUE').collect(&:text).first if elem.search('TAG').collect(&:text).first == tag_name
    end
end

RSpec.describe Accession::Sample, :accession, type: :model do
  include Accession::Helpers

  let(:folder) { File.join('spec', 'data', 'accession') }
  let(:yaml) { load_file(folder, 'tags') }
  let(:tag_list) { Accession::TagList.new(yaml) }

  before do
    create(:insdc_country, name: 'Australia')
    create(:insdc_country, name: 'Niue')
  end

  it 'is not sent for accessioning if the sample has already been accessioned' do
    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_ebi_accession_number: 'ENA123')
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it "is not sent for accessioning if the sample doesn't have an appropriate study" do
    expect(described_class.new(tag_list, create(:sample))).not_to be_valid
    expect(described_class.new(tag_list, create(:sample, studies: [create(:open_study)]))).not_to be_valid

    sample =
      create(
        :sample,
        studies: [create(:open_study, accession_number: 'ENA123'), create(:managed_study, accession_number: 'ENA123')]
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  context 'when validating' do
    let(:sample_metadata) { create(:sample_metadata_for_accessioning) }

    context 'with an open study' do
      let(:sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }

      it 'is required to define sample_taxon_id' do
        sample.sample_metadata.sample_taxon_id = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end

      it 'is required to define sample_common_name' do
        sample.sample_metadata.sample_common_name = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end
    end

    context 'with a managed study' do
      let(:sample) { create(:sample_for_accessioning_with_managed_study, sample_metadata:) }

      it 'is required to define sample_taxon_id' do
        sample.sample_metadata.sample_taxon_id = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end

      it 'is required to define sample_common_name' do
        sample.sample_metadata.sample_common_name = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end

      it 'is required to define gender' do
        sample.sample_metadata.gender = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end

      it 'is required to define phenotype' do
        sample.sample_metadata.phenotype = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end

      it 'is required to define donor_id' do
        sample.sample_metadata.donor_id = nil
        expect(described_class.new(tag_list, sample)).not_to be_valid
      end
    end
  end

  it 'an appropriate service should be chosen based on the associated study' do
    sample = create(:sample_for_accessioning_with_open_study)
    expect(described_class.new(tag_list, sample).service).to be_ena

    sample = create(:sample_for_accessioning_with_managed_study)
    expect(described_class.new(tag_list, sample).service).to be_ega

    sample = create(:sample, studies: [create(:open_study)])
    expect(described_class.new(tag_list, sample).service).not_to be_valid
  end

  it 'has a name and a title' do
    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: 'Sample 666')
      )
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_666')
    expect(accession_sample.title).to eq('Sample 666')

    sample =
      create(
        :sample_for_accessioning_with_open_study,
        name: 'Sample_1-',
        sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: nil)
      )
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_1_')
    expect(accession_sample.title).to eq(sample.sanger_sample_id)
  end

  it 'creates some xml with valid attributes' do
    accession_sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
    xml = accession_sample.to_xml

    expect(xml).to match(%r{<SAMPLE_SET.*<SAMPLE.*</SAMPLE>.*</SAMPLE_SET>}m)
    expect(xml).to include(%r{<SAMPLE_SET.*<SAMPLE_ATTRIBUTES>.*</SAMPLE_ATTRIBUTES>.*</SAMPLE_SET>}m)

    expect(xml).to include("alias=\"#{accession_sample.ebi_alias}\"")
    expect(xml).to include("<TITLE>#{accession_sample.title}</TITLE>")

    tags = accession_sample.tags.by_group[:sample_name]
    sample_name_tags = xml
    tags.each do |_label, tag|
      expected_tag = tag.label.tr(' ', '_').upcase
      expect(sample_name_tags).to include("<#{expected_tag}>#{tag.value}</#{expected_tag}>")
    end

    sample_attributes_tags = xml

    tags_array = accession_sample.tags.by_group[:sample_attributes]

    tags_array.each do |_key, tag|
      label = tag.label
      value = tag.value

      expect(sample_attributes_tags).to include("<TAG>#{label}</TAG>")

      # gender is downcased specifically in the XML
      value = value.downcase if label == 'gender'

      expect(sample_attributes_tags).to include("<VALUE>#{value}</VALUE>")
    end

    tags = accession_sample.tags.by_group[:array_express]
    expect(sample_attributes_tags).to include(*tags.array_express_labels.map { |label| "<TAG>#{label}</TAG>" })
    expect(sample_attributes_tags).to include(*tags.values.map { |value| "<VALUE>#{value}</VALUE>" })

    accession_sample = described_class.new(tag_list, create(:sample_for_accessioning_with_managed_study))
    xml = accession_sample.to_xml
    sample_attributes_tags = xml
    expect(sample_attributes_tags).not_to include(*tags.array_express_labels.map { |label| "<TAG>#{label}</TAG>" })
  end

  describe '#update_accession_number' do
    let(:event_user) { create(:user) }
    let(:sample) { create(:sample_for_accessioning_with_open_study) }
    let(:accession_sample) { described_class.new(tag_list, sample) }
    let(:test_accession_number) { 'ENA12345' }

    before do
      expect(accession_sample.ebi_accession_number).to be_nil
      accession_sample.update_accession_number(test_accession_number, event_user)
    end

    it 'sets the ebi_accession_number to the provided value' do
      expect(accession_sample.ebi_accession_number).to eq(test_accession_number)
    end

    it 'creates an event indicating the accession data has been updated' do
      event = sample.events.order(:created_at).last
      expect(event).to have_attributes(
        message: 'Assigned sample accession number',
        content: test_accession_number,
        of_interest_to: 'administrators',
        created_by: event_user.login
      )
    end
  end

  describe '#to_xml' do
    let(:sample) { create(:sample_for_accessioning_with_open_study) }
    let(:accession_sample) { described_class.new(tag_list, sample) }
    let(:xml) { accession_sample.to_xml }

    context 'with country of origin' do
      it 'includes country of origin' do
        expect(xml).to include(COUNTRY_TAG)
      end

      it 'displays the country when country is specified' do
        expect(find_value_at_tag(xml, COUNTRY_TAG)).to eq('Australia')
      end

      it 'displays not provided when country is empty' do
        sample.sample_metadata.update(country_of_origin: nil)
        expect(find_value_at_tag(xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays not provided when country value is not provided' do
        sample.sample_metadata.update(country_of_origin: 'not provided')
        expect(find_value_at_tag(xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays not provided when country value is wrong' do
        sample.sample_metadata.update(country_of_origin: 'Freedonia')
        expect(find_value_at_tag(xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays missing when country of origin is specified as missing' do
        sample.sample_metadata.update(country_of_origin: 'missing: human-identifiable')
        expect(find_value_at_tag(xml, COUNTRY_TAG)).to eq('missing: human-identifiable')
      end
    end

    context 'with collection date' do
      it 'includes collection date' do
        expect(xml).to include(COLLECTION_DATE_TAG)
      end

      it 'displays the collection date when correctly specified' do
        expect(find_value_at_tag(xml, COLLECTION_DATE_TAG)).to eq('2000-01-01T00:00')
      end

      it 'displays not provided when collection date is empty' do
        sample.sample_metadata.update(date_of_sample_collection: nil)
        expect(find_value_at_tag(xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays not provided when collection date is not provided' do
        sample.sample_metadata.update(date_of_sample_collection: 'not provided')
        expect(find_value_at_tag(xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays not provided when collection date is wrong' do
        sample.sample_metadata.update(date_of_sample_collection: '2000-99-01T00:00')
        expect(find_value_at_tag(xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays missing when collection date is specified as missing' do
        sample.sample_metadata.update(date_of_sample_collection: 'missing: human-identifiable')
        expect(find_value_at_tag(xml, COLLECTION_DATE_TAG)).to eq('missing: human-identifiable')
      end
    end

    context 'with all possible tags' do
      # This section shows which tags are generated in the XML under which circumstances.
      # This is technically more of an integration test as it involves several classes, but I
      # needed a clear way to easily validate generated output.

      # Uses the actual tag list loaded from config, not the factory
      before do
        Accession.configure do |config|
          config.folder = File.join('config', 'accession')
          config.load!
        end
      end

      let(:tag_list) { Accession.configuration.tags }
      let(:sample_metadata) do
        create(
          :minimal_sample_metadata_for_accessioning,

          # "Standard" and ENA
          organism: 'organism',
          cohort: 'cohort',
          country_of_origin: 'Niue', # A South Pacific island, now you know: https://en.wikipedia.org/wiki/Niue
          geographical_region: 'geographical_region',
          ethnicity: 'ethnicity',
          volume: 'volume',
          mother: 'mother',
          father: 'father',
          replicate: 'replicate',
          gc_content: 'High AT',
          gender: 'Female',
          donor_id: 'donor_id',
          dna_source: 'Brain',
          sample_public_name: 'sample_public_name',
          sample_ebi_accession_number: 'sample_ebi_accession_number',
          sample_description: 'sample_description',
          sample_sra_hold: 'Protect',
          sibling: 'sibling',
          is_resubmitted: 'is_resubmitted',
          date_of_sample_collection: '2020-02-02',
          date_of_sample_extraction: 'date_of_sample_extraction',
          sample_extraction_method: 'sample_extraction_method',
          sample_purified: 'sample_purified',
          purification_method: 'purification_method',
          concentration: 'concentration',
          concentration_determined_by: 'concentration_determined_by',
          sample_type: 'sample_type',
          sample_storage_conditions: 'sample_storage_conditions',
          collected_by: 'collected_by',

          # Array Express
          genotype: 'genotype',
          phenotype: 'phenotype',
          sample_strain_att: 'sample_strain_att', # strain
          age: '23 seconds',
          developmental_stage: 'developmental_stage',
          cell_type: 'cell_type',
          disease_state: 'disease_state',
          compound: 'compound',
          dose: '50 units',
          immunoprecipitate: 'immunoprecipitate',
          growth_condition: 'growth_condition',
          rnai: 'rnai',
          organism_part: 'organism_part',
          time_point: 'time_point',

          # EGA
          treatment: 'treatment',
          subject: 'subject',
          disease: 'disease',
          genome_size: 'genome_size',
          consent_withdrawn: 'consent_withdrawn',
          date_of_consent_withdrawn: 'date_of_consent_withdrawn',
          user_id_of_consent_withdrawn: 'user_id_of_consent_withdrawn'
        )
      end

      RSpec.shared_examples 'the tags are correctly included in the generated XML' do
        let(:xml_sample_attributes) do
          doc = Nokogiri::XML(xml) # takes in the XML generated by accession_sample.to_xml
          sample_attributes = doc.at('SAMPLE_ATTRIBUTES')
          return {} unless sample_attributes

          sample_attributes.search('SAMPLE_ATTRIBUTE').each_with_object({}) do |attr, hash|
            tag = attr.at('TAG')&.text
            value = attr.at('VALUE')&.text
            hash[tag] = value
          end
        end

        it 'expects all provided expected values to be non-nil' do
          # This is to make sure that values are sourced from the data locations above and are not defaulting to nil
          nil_tags = expected_tags_and_values.select { |_, value| value.nil? }.keys
          expect(nil_tags).to be_empty, "Expected non-nil values for tags: #{nil_tags.join(', ')}"
        end

        it 'includes the EBI names of all expected tags' do
          missing_tags = expected_tags_and_values.keys - xml_sample_attributes.keys
          expect(missing_tags).to be_empty,
                                  "Expected XML to include tags: '#{missing_tags.join("', '")}' " \
                                  "but only tags '#{xml_sample_attributes.keys.join("', '")}' were found"
        end

        it 'includes the correct values for all expected tags' do
          tag_value_received = expected_tags_and_values.filter_map do |tag, value|
            [tag, value, xml_sample_attributes[tag]] if xml_sample_attributes[tag] != value
          end
          expect(tag_value_received)
            .to be_empty, 'Incorrect tag values found: ' \
                          "#{tag_value_received.map do |tag, expected, received|
                            "'#{tag}': expected #{expected.inspect}, received #{received.inspect}"
                          end.join('; ')}"
        end

        it 'does not include tags not in the expected tag list' do
          unexpected_tags = xml_sample_attributes.keys - expected_tags_and_values.keys
          expect(unexpected_tags).to be_empty,
                                     "Unexpected tags found in XML: '#{unexpected_tags.join("', '")}'"
        end
      end

      context 'with an OPEN study' do # study emphasised for easy test failure identification
        let(:sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }
        let(:expected_tags_and_values) do
          {
            # EBI tag name => datasource
            'collection date' => sample.sample_metadata.date_of_sample_collection,
            'gender' => sample.sample_metadata.gender.downcase,
            'geographic location (country and/or sea)' => sample.sample_metadata.country_of_origin,
            'phenotype' => sample.sample_metadata.phenotype,
            'sample description' => sample.sample_metadata.sample_description,
            'strain' => sample.sample_metadata.sample_strain_att,
            'subject id' => sample.sample_metadata.donor_id,
            'ArrayExpress-AGE' => sample.sample_metadata.age,
            'ArrayExpress-CELL_TYPE' => sample.sample_metadata.cell_type,
            'ArrayExpress-COMPOUND' => sample.sample_metadata.compound,
            'ArrayExpress-DEVELOPMENTAL_STAGE' => sample.sample_metadata.developmental_stage,
            'ArrayExpress-DISEASE_STATE' => sample.sample_metadata.disease_state,
            'ArrayExpress-DOSE' => sample.sample_metadata.dose,
            'ArrayExpress-GENOTYPE' => sample.sample_metadata.genotype,
            'ArrayExpress-GROWTH_CONDITION' => sample.sample_metadata.growth_condition,
            'ArrayExpress-IMMUNOPRECIPITATE' => sample.sample_metadata.immunoprecipitate,
            'ArrayExpress-ORGANISM_PART' => sample.sample_metadata.organism_part,
            'ArrayExpress-PHENOTYPE' => sample.sample_metadata.phenotype,
            'ArrayExpress-RNAI' => sample.sample_metadata.rnai,
            'ArrayExpress-SEX' => sample.sample_metadata.gender.downcase,
            'ArrayExpress-SPECIES' => sample.sample_metadata.sample_common_name,
            'ArrayExpress-STRAIN_OR_LINE' => sample.sample_metadata.sample_strain_att,
            'ArrayExpress-TIME_POINT' => sample.sample_metadata.time_point,
            'ArrayExpress-TREATMENT' => sample.sample_metadata.treatment
          }
        end

        it_behaves_like 'the tags are correctly included in the generated XML'
      end

      context 'with a MANAGED study' do # study emphasised for easy test failure identification
        let(:sample) { create(:sample_for_accessioning_with_managed_study, sample_metadata:) }

        let(:expected_tags_and_values) do
          {
            # EBI tag name => datasource
            'collection date' => sample.sample_metadata.date_of_sample_collection,
            'gender' => sample.sample_metadata.gender.downcase,
            'geographic location (country and/or sea)' => sample.sample_metadata.country_of_origin,
            'phenotype' => sample.sample_metadata.phenotype,
            'sample description' => sample.sample_metadata.sample_description,
            'strain' => sample.sample_metadata.sample_strain_att,
            'subject id' => sample.sample_metadata.donor_id
          }
        end

        it_behaves_like 'the tags are correctly included in the generated XML'
      end
    end
  end
end
