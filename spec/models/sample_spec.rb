require 'rails_helper'

RSpec.describe Sample, type: :model, accession: true do
  include MockAccession

  context 'accessioning' do
    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    before(:each) do
      configatron.accession_samples = true
      Delayed::Worker.delay_jobs = false
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'accession')
        config.load!
      end
    end

    after(:each) do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = false
    end

    it 'will not proceed if the sample is not suitable' do
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end

    it 'will add an accession number if successful' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_accession_response)
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_present
    end

    it 'will not add an accession number if it fails' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end
  end

  context 'can be included in submission' do
    it 'knows if it was registered through manifest' do
      stand_alone_sample = create :sample
      expect(stand_alone_sample.registered_through_manifest?).to be_falsey

      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample.registered_through_manifest?).to be_truthy
      end
    end

    it 'knows when it can be included in submission if it was registered through manifest' do
      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample.can_be_included_in_submission?).to be_falsey
      end
      sample = sample_manifest.samples.first
      sample.sample_metadata.supplier_name = 'new sample'
      expect(sample.can_be_included_in_submission?).to be_truthy
    end

    it 'knows when it can be included in submission if it was not registered through manifest' do
      sample = create :sample
      expect(sample.can_be_included_in_submission?).to be_truthy
    end
  end

  context 'Aker' do
    it 'can have many work orders' do
      work_order = create(:aker_work_order)
      expect(create(:sample, work_orders: [work_order]).work_orders).to include(work_order)
    end

    it 'can belong to a container' do
      container = create(:container)
      expect(create(:sample, container: container).container).to eq(container)
    end
  end

  context 'metadata attributes' do
    let(:sample) { create :sample }

    it 'has organism' do
        sample.sample_metadata.update_attributes(organism: 'organism 1')
        expect(sample.sample_metadata.organism).to eq('organism 1')
    end


    it 'has cohort' do
        sample.sample_metadata.update_attributes(cohort: 'cohort 1')
        expect(sample.sample_metadata.cohort).to eq('cohort 1')
    end


    it 'has country_of_origin' do
        sample.sample_metadata.update_attributes(country_of_origin: 'country_of_origin 1')
        expect(sample.sample_metadata.country_of_origin).to eq('country_of_origin 1')
    end


    it 'has geographical_region' do
        sample.sample_metadata.update_attributes(geographical_region: 'geographical_region 1')
        expect(sample.sample_metadata.geographical_region).to eq('geographical_region 1')
    end


    it 'has ethnicity' do
        sample.sample_metadata.update_attributes(ethnicity: 'ethnicity 1')
        expect(sample.sample_metadata.ethnicity).to eq('ethnicity 1')
    end


    it 'has volume' do
        sample.sample_metadata.update_attributes(volume: 'volume 1')
        expect(sample.sample_metadata.volume).to eq('volume 1')
    end


    it 'has supplier_plate_id' do
        sample.sample_metadata.update_attributes(supplier_plate_id: 'supplier_plate_id 1')
        expect(sample.sample_metadata.supplier_plate_id).to eq('supplier_plate_id 1')
    end


    it 'has mother' do
        sample.sample_metadata.update_attributes(mother: 'mother 1')
        expect(sample.sample_metadata.mother).to eq('mother 1')
    end


    it 'has father' do
        sample.sample_metadata.update_attributes(father: 'father 1')
        expect(sample.sample_metadata.father).to eq('father 1')
    end


    it 'has replicate' do
        sample.sample_metadata.update_attributes(replicate: 'replicate 1')
        expect(sample.sample_metadata.replicate).to eq('replicate 1')
    end


    it 'has gc_content' do
        sample.sample_metadata.update_attributes(gc_content: 'gc_content 1')
        expect(sample.sample_metadata.gc_content).to eq('gc_content 1')
    end


    it 'has gender' do
        sample.sample_metadata.update_attributes(gender: 'gender 1')
        expect(sample.sample_metadata.gender).to eq('gender 1')
    end


    it 'has donor_id' do
        sample.sample_metadata.update_attributes(donor_id: 'donor_id 1')
        expect(sample.sample_metadata.donor_id).to eq('donor_id 1')
    end


    it 'has dna_source' do
        sample.sample_metadata.update_attributes(dna_source: 'dna_source 1')
        expect(sample.sample_metadata.dna_source).to eq('dna_source 1')
    end


    it 'has sample_public_name' do
        sample.sample_metadata.update_attributes(sample_public_name: 'sample_public_name 1')
        expect(sample.sample_metadata.sample_public_name).to eq('sample_public_name 1')
    end


    it 'has sample_common_name' do
        sample.sample_metadata.update_attributes(sample_common_name: 'sample_common_name 1')
        expect(sample.sample_metadata.sample_common_name).to eq('sample_common_name 1')
    end


    it 'has sample_strain_att' do
        sample.sample_metadata.update_attributes(sample_strain_att: 'sample_strain_att 1')
        expect(sample.sample_metadata.sample_strain_att).to eq('sample_strain_att 1')
    end


    it 'has sample_taxon_id' do
        sample.sample_metadata.update_attributes(sample_taxon_id: 1)
        expect(sample.sample_metadata.sample_taxon_id).to eq(1)
    end


    it 'has sample_ebi_accession_number' do
        sample.sample_metadata.update_attributes(sample_ebi_accession_number: 'sample_ebi_accession_number 1')
        expect(sample.sample_metadata.sample_ebi_accession_number).to eq('sample_ebi_accession_number 1')
    end


    it 'has sample_description' do
        sample.sample_metadata.update_attributes(sample_description: 'sample_description 1')
        expect(sample.sample_metadata.sample_description).to eq('sample_description 1')
    end


    it 'has sample_sra_hold' do
        sample.sample_metadata.update_attributes(sample_sra_hold: 'sample_sra_hold 1')
        expect(sample.sample_metadata.sample_sra_hold).to eq('sample_sra_hold 1')
    end


    it 'has sibling' do
        sample.sample_metadata.update_attributes(sibling: 'sibling 1')
        expect(sample.sample_metadata.sibling).to eq('sibling 1')
    end


    it 'has is_resubmitted' do
        sample.sample_metadata.update_attributes(is_resubmitted: true)
        expect(sample.sample_metadata.is_resubmitted).to be_truthy
    end


    it 'has date_of_sample_collection' do
        sample.sample_metadata.update_attributes(date_of_sample_collection: 'date_of_sample_collection 1')
        expect(sample.sample_metadata.date_of_sample_collection).to eq('date_of_sample_collection 1')
    end


    it 'has date_of_sample_extraction' do
        sample.sample_metadata.update_attributes(date_of_sample_extraction: 'date_of_sample_extraction 1')
        expect(sample.sample_metadata.date_of_sample_extraction).to eq('date_of_sample_extraction 1')
    end


    it 'has sample_extraction_method' do
        sample.sample_metadata.update_attributes(sample_extraction_method: 'sample_extraction_method 1')
        expect(sample.sample_metadata.sample_extraction_method).to eq('sample_extraction_method 1')
    end


    it 'has sample_purified' do
        sample.sample_metadata.update_attributes(sample_purified: 'sample_purified 1')
        expect(sample.sample_metadata.sample_purified).to eq('sample_purified 1')
    end


    it 'has purification_method' do
        sample.sample_metadata.update_attributes(purification_method: 'purification_method 1')
        expect(sample.sample_metadata.purification_method).to eq('purification_method 1')
    end


    it 'has concentration' do
        sample.sample_metadata.update_attributes(concentration: 'concentration 1')
        expect(sample.sample_metadata.concentration).to eq('concentration 1')
    end


    it 'has concentration_determined_by' do
        sample.sample_metadata.update_attributes(concentration_determined_by: 'concentration_determined_by 1')
        expect(sample.sample_metadata.concentration_determined_by).to eq('concentration_determined_by 1')
    end


    it 'has sample_type' do
        sample.sample_metadata.update_attributes(sample_type: 'sample_type 1')
        expect(sample.sample_metadata.sample_type).to eq('sample_type 1')
    end


    it 'has sample_storage_conditions' do
        sample.sample_metadata.update_attributes(sample_storage_conditions: 'sample_storage_conditions 1')
        expect(sample.sample_metadata.sample_storage_conditions).to eq('sample_storage_conditions 1')
    end


    it 'has genotype' do
        sample.sample_metadata.update_attributes(genotype: 'genotype 1')
        expect(sample.sample_metadata.genotype).to eq('genotype 1')
    end


    it 'has phenotype' do
        sample.sample_metadata.update_attributes(phenotype: 'phenotype 1')
        expect(sample.sample_metadata.phenotype).to eq('phenotype 1')
    end


    it 'has age' do
        sample.sample_metadata.update_attributes(age: 'age 1')
        expect(sample.sample_metadata.age).to eq('age 1')
    end


    it 'has developmental_stage' do
        sample.sample_metadata.update_attributes(developmental_stage: 'developmental_stage 1')
        expect(sample.sample_metadata.developmental_stage).to eq('developmental_stage 1')
    end


    it 'has cell_type' do
        sample.sample_metadata.update_attributes(cell_type: 'cell_type 1')
        expect(sample.sample_metadata.cell_type).to eq('cell_type 1')
    end


    it 'has disease_state' do
        sample.sample_metadata.update_attributes(disease_state: 'disease_state 1')
        expect(sample.sample_metadata.disease_state).to eq('disease_state 1')
    end


    it 'has compound' do
        sample.sample_metadata.update_attributes(compound: 'compound 1')
        expect(sample.sample_metadata.compound).to eq('compound 1')
    end


    it 'has dose' do
        sample.sample_metadata.update_attributes(dose: 'dose 1')
        expect(sample.sample_metadata.dose).to eq('dose 1')
    end


    it 'has immunoprecipitate' do
        sample.sample_metadata.update_attributes(immunoprecipitate: 'immunoprecipitate 1')
        expect(sample.sample_metadata.immunoprecipitate).to eq('immunoprecipitate 1')
    end


    it 'has growth_condition' do
        sample.sample_metadata.update_attributes(growth_condition: 'growth_condition 1')
        expect(sample.sample_metadata.growth_condition).to eq('growth_condition 1')
    end


    it 'has rnai' do
        sample.sample_metadata.update_attributes(rnai: 'rnai 1')
        expect(sample.sample_metadata.rnai).to eq('rnai 1')
    end


    it 'has organism_part' do
        sample.sample_metadata.update_attributes(organism_part: 'organism_part 1')
        expect(sample.sample_metadata.organism_part).to eq('organism_part 1')
    end


    it 'has time_point' do
        sample.sample_metadata.update_attributes(time_point: 'time_point 1')
        expect(sample.sample_metadata.time_point).to eq('time_point 1')
    end


    it 'has treatment' do
        sample.sample_metadata.update_attributes(treatment: 'treatment 1')
        expect(sample.sample_metadata.treatment).to eq('treatment 1')
    end


    it 'has subject' do
        sample.sample_metadata.update_attributes(subject: 'subject 1')
        expect(sample.sample_metadata.subject).to eq('subject 1')
    end


    it 'has disease' do
        sample.sample_metadata.update_attributes(disease: 'disease 1')
        expect(sample.sample_metadata.disease).to eq('disease 1')
    end

    it 'remap sample_strain_att to strain_or_line' do
      sample.sample_metadata.update_attributes(sample_strain_att: 'strain att')
      expect(sample.sample_metadata.strain_or_line).to eq('strain att')
    end

    it 'remap gender to sex (downcase)' do
      sample.sample_metadata.update_attributes(gender: 'MALE')
      expect(sample.sample_metadata.sex).to eq('male')
    end

    it 'remap sample_common_name to species' do
      sample.sample_metadata.update_attributes(sample_common_name: 'common name')
      expect(sample.sample_metadata.species).to eq('common name')
    end

    it 'is associated with reference genome' do
      expect(sample.sample_metadata.reference_genome).to be_present
    end

    it 'can set the reference genome by name' do
      reference_genome = create :reference_genome, name: 'reference genome 1'
      sample.sample_metadata.reference_genome_name = reference_genome.name
      expect(sample.sample_metadata.reference_genome.name).to eq(reference_genome.name)
    end

    it 'validation succeed if reference genome name found' do
      reference_genome = create :reference_genome, name: 'reference genome 1'
      sample.sample_metadata.reference_genome_name = reference_genome.name
      expect(sample).to be_valid
    end

    it 'validation fails if reference genome not found' do
      create :reference_genome, name: 'reference genome 1'
      sample.sample_metadata.reference_genome_name = 'inexistent reference genome'
      expect(sample).to_not be_valid
    end

    it 'remaps attributes correctly' do
      sample.sample_metadata.update_attributes(gc_content: 'NEUTRAL')
      sample.sample_metadata.update_attributes(gender: 'MALE')
      sample.sample_metadata.update_attributes(dna_source: 'GENOMIC')
      sample.sample_metadata.update_attributes(sample_sra_hold: 'HOLD')
      expect(sample).to be_valid
      expect(sample.sample_metadata.gc_content).to eq('Neutral')
      expect(sample.sample_metadata.gender).to eq('Male')
      expect(sample.sample_metadata.dna_source).to eq('Genomic')
      expect(sample.sample_metadata.sample_sra_hold).to eq('Hold')
    end

  end

end
