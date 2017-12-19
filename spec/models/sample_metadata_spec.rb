require 'rails_helper'

RSpec.describe SampleMetadata, type: :model do

  context 'metadata attributes' do
    let(:sample_metadata) { SampleMetadata.create! }

    it 'has organism' do
      sample_metadata.update_attributes(organism: 'organism 1')
      expect(sample_metadata.organism).to eq('organism 1')
    end


    it 'has cohort' do
      sample_metadata.update_attributes(cohort: 'cohort 1')
      expect(sample_metadata.cohort).to eq('cohort 1')
    end


    it 'has country_of_origin' do
      sample_metadata.update_attributes(country_of_origin: 'country_of_origin 1')
      expect(sample_metadata.country_of_origin).to eq('country_of_origin 1')
    end


    it 'has geographical_region' do
      sample_metadata.update_attributes(geographical_region: 'geographical_region 1')
      expect(sample_metadata.geographical_region).to eq('geographical_region 1')
    end


    it 'has ethnicity' do
      sample_metadata.update_attributes(ethnicity: 'ethnicity 1')
      expect(sample_metadata.ethnicity).to eq('ethnicity 1')
    end


    it 'has volume' do
      sample_metadata.update_attributes(volume: 'volume 1')
      expect(sample_metadata.volume).to eq('volume 1')
    end


    it 'has supplier_plate_id' do
      sample_metadata.update_attributes(supplier_plate_id: 'supplier_plate_id 1')
      expect(sample_metadata.supplier_plate_id).to eq('supplier_plate_id 1')
    end


    it 'has mother' do
      sample_metadata.update_attributes(mother: 'mother 1')
      expect(sample_metadata.mother).to eq('mother 1')
    end


    it 'has father' do
      sample_metadata.update_attributes(father: 'father 1')
      expect(sample_metadata.father).to eq('father 1')
    end


    it 'has replicate' do
      sample_metadata.update_attributes(replicate: 'replicate 1')
      expect(sample_metadata.replicate).to eq('replicate 1')
    end


    it 'has gc_content' do
      sample_metadata.update_attributes(gc_content: 'gc_content 1')
      expect(sample_metadata.gc_content).to eq('gc_content 1')
    end


    it 'has gender' do
      sample_metadata.update_attributes(gender: 'gender 1')
      expect(sample_metadata.gender).to eq('gender 1')
    end


    it 'has donor_id' do
      sample_metadata.update_attributes(donor_id: 'donor_id 1')
      expect(sample_metadata.donor_id).to eq('donor_id 1')
    end


    it 'has dna_source' do
      sample_metadata.update_attributes(dna_source: 'dna_source 1')
      expect(sample_metadata.dna_source).to eq('dna_source 1')
    end


    it 'has sample_public_name' do
      sample_metadata.update_attributes(sample_public_name: 'sample_public_name 1')
      expect(sample_metadata.sample_public_name).to eq('sample_public_name 1')
    end


    it 'has sample_common_name' do
      sample_metadata.update_attributes(sample_common_name: 'sample_common_name 1')
      expect(sample_metadata.sample_common_name).to eq('sample_common_name 1')
    end


    it 'has sample_strain_att' do
      sample_metadata.update_attributes(sample_strain_att: 'sample_strain_att 1')
      expect(sample_metadata.sample_strain_att).to eq('sample_strain_att 1')
    end


    it 'has sample_taxon_id' do
      sample_metadata.update_attributes(sample_taxon_id: 1)
      expect(sample_metadata.sample_taxon_id).to eq(1)
    end


    it 'has sample_ebi_accession_number' do
      sample_metadata.update_attributes(sample_ebi_accession_number: 'sample_ebi_accession_number 1')
      expect(sample_metadata.sample_ebi_accession_number).to eq('sample_ebi_accession_number 1')
    end


    it 'has sample_description' do
      sample_metadata.update_attributes(sample_description: 'sample_description 1')
      expect(sample_metadata.sample_description).to eq('sample_description 1')
    end


    it 'has sample_sra_hold' do
      sample_metadata.update_attributes(sample_sra_hold: 'sample_sra_hold 1')
      expect(sample_metadata.sample_sra_hold).to eq('sample_sra_hold 1')
    end


    it 'has sibling' do
      sample_metadata.update_attributes(sibling: 'sibling 1')
      expect(sample_metadata.sibling).to eq('sibling 1')
    end


    it 'has is_resubmitted' do
      sample_metadata.update_attributes(is_resubmitted: true)
      expect(sample_metadata.is_resubmitted).to be_truthy
    end


    it 'has date_of_sample_collection' do
      sample_metadata.update_attributes(date_of_sample_collection: 'date_of_sample_collection 1')
      expect(sample_metadata.date_of_sample_collection).to eq('date_of_sample_collection 1')
    end


    it 'has date_of_sample_extraction' do
      sample_metadata.update_attributes(date_of_sample_extraction: 'date_of_sample_extraction 1')
      expect(sample_metadata.date_of_sample_extraction).to eq('date_of_sample_extraction 1')
    end


    it 'has sample_extraction_method' do
      sample_metadata.update_attributes(sample_extraction_method: 'sample_extraction_method 1')
      expect(sample_metadata.sample_extraction_method).to eq('sample_extraction_method 1')
    end


    it 'has sample_purified' do
      sample_metadata.update_attributes(sample_purified: 'sample_purified 1')
      expect(sample_metadata.sample_purified).to eq('sample_purified 1')
    end


    it 'has purification_method' do
      sample_metadata.update_attributes(purification_method: 'purification_method 1')
      expect(sample_metadata.purification_method).to eq('purification_method 1')
    end


    it 'has concentration' do
      sample_metadata.update_attributes(concentration: 'concentration 1')
      expect(sample_metadata.concentration).to eq('concentration 1')
    end


    it 'has concentration_determined_by' do
      sample_metadata.update_attributes(concentration_determined_by: 'concentration_determined_by 1')
      expect(sample_metadata.concentration_determined_by).to eq('concentration_determined_by 1')
    end


    it 'has sample_type' do
      sample_metadata.update_attributes(sample_type: 'sample_type 1')
      expect(sample_metadata.sample_type).to eq('sample_type 1')
    end


    it 'has sample_storage_conditions' do
      sample_metadata.update_attributes(sample_storage_conditions: 'sample_storage_conditions 1')
      expect(sample_metadata.sample_storage_conditions).to eq('sample_storage_conditions 1')
    end


    it 'has genotype' do
      sample_metadata.update_attributes(genotype: 'genotype 1')
      expect(sample_metadata.genotype).to eq('genotype 1')
    end


    it 'has phenotype' do
      sample_metadata.update_attributes(phenotype: 'phenotype 1')
      expect(sample_metadata.phenotype).to eq('phenotype 1')
    end


    it 'has age' do
      sample_metadata.update_attributes(age: 'age 1')
      expect(sample_metadata.age).to eq('age 1')
    end


    it 'has developmental_stage' do
      sample_metadata.update_attributes(developmental_stage: 'developmental_stage 1')
      expect(sample_metadata.developmental_stage).to eq('developmental_stage 1')
    end


    it 'has cell_type' do
      sample_metadata.update_attributes(cell_type: 'cell_type 1')
      expect(sample_metadata.cell_type).to eq('cell_type 1')
    end


    it 'has disease_state' do
      sample_metadata.update_attributes(disease_state: 'disease_state 1')
      expect(sample_metadata.disease_state).to eq('disease_state 1')
    end


    it 'has compound' do
      sample_metadata.update_attributes(compound: 'compound 1')
      expect(sample_metadata.compound).to eq('compound 1')
    end


    it 'has dose' do
      sample_metadata.update_attributes(dose: 'dose 1')
      expect(sample_metadata.dose).to eq('dose 1')
    end


    it 'has immunoprecipitate' do
      sample_metadata.update_attributes(immunoprecipitate: 'immunoprecipitate 1')
      expect(sample_metadata.immunoprecipitate).to eq('immunoprecipitate 1')
    end


    it 'has growth_condition' do
      sample_metadata.update_attributes(growth_condition: 'growth_condition 1')
      expect(sample_metadata.growth_condition).to eq('growth_condition 1')
    end


    it 'has rnai' do
      sample_metadata.update_attributes(rnai: 'rnai 1')
      expect(sample_metadata.rnai).to eq('rnai 1')
    end


    it 'has organism_part' do
      sample_metadata.update_attributes(organism_part: 'organism_part 1')
      expect(sample_metadata.organism_part).to eq('organism_part 1')
    end


    it 'has time_point' do
      sample_metadata.update_attributes(time_point: 'time_point 1')
      expect(sample_metadata.time_point).to eq('time_point 1')
    end


    it 'has treatment' do
      sample_metadata.update_attributes(treatment: 'treatment 1')
      expect(sample_metadata.treatment).to eq('treatment 1')
    end


    it 'has subject' do
      sample_metadata.update_attributes(subject: 'subject 1')
      expect(sample_metadata.subject).to eq('subject 1')
    end


    it 'has disease' do
      sample_metadata.update_attributes(disease: 'disease 1')
      expect(sample_metadata.disease).to eq('disease 1')
    end

    it 'remap sample_strain_att to strain_or_line' do
      sample_metadata.update_attributes(sample_strain_att: 'strain att')
      expect(sample_metadata.strain_or_line).to eq('strain att')
    end

    it 'remap gender to sex (downcase)' do
      sample_metadata.update_attributes(gender: 'MALE')
      expect(sample_metadata.sex).to eq('male')
    end

    it 'remap sample_common_name to species' do
      sample_metadata.update_attributes(sample_common_name: 'common name')
      expect(sample_metadata.species).to eq('common name')
    end

    it 'is associated with reference genome' do
      expect(sample_metadata.reference_genome).to be_present
    end

    it 'can set the reference genome by name' do
      reference_genome = create :reference_genome, name: 'reference genome 1'
      sample_metadata.reference_genome_name = reference_genome.name
      expect(sample_metadata.reference_genome.name).to eq(reference_genome.name)
    end

    it 'succesfully validates sample if reference genome name found' do
      reference_genome = create :reference_genome, name: 'reference genome 1'
      sample_metadata.reference_genome_name = reference_genome.name
      expect(sample_metadata).to be_valid
    end

    it 'fails validation if reference genome not found' do
      create :reference_genome, name: 'reference genome 1'
      sample_metadata.reference_genome_name = 'inexistent reference genome'
      expect(sample_metadata).to_not be_valid
    end

    it 'remaps attributes correctly' do
      sample_metadata.update_attributes(gc_content: 'NEUTRAL')
      sample_metadata.update_attributes(gender: 'MALE')
      sample_metadata.update_attributes(dna_source: 'GENOMIC')
      sample_metadata.update_attributes(sample_sra_hold: 'HOLD')
      expect(sample_metadata).to be_valid
      expect(sample_metadata.gc_content).to eq('Neutral')
      expect(sample_metadata.gender).to eq('Male')
      expect(sample_metadata.dna_source).to eq('Genomic')
      expect(sample_metadata.sample_sra_hold).to eq('Hold')
      sample_metadata.update_attributes(gender: '')
      expect(sample_metadata).to be_valid
      expect(sample_metadata.gender).to eq(nil)
    end

  end
end
