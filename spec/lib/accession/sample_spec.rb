require 'rails_helper'

RSpec.describe Accession::Sample, type: :model do

  let(:metadata)      { { sample_taxon_id: 1, sample_common_name: "A common name", 
                          gender: "Unknown", phenotype: "Indescribeable", donor_id: 1,
                          sample_public_name: "Sample 666", disease_state: "Awful" } }
  let!(:open_study)   { create(:open_study, accession_number: "ENA123") }
  let!(:managed_study)  { create(:managed_study, accession_number: "ENA123") }

  it "should be sent for accessioning if the sample is valid" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample)).to be_valid
  end

  it "should not be sent for accessioning if the sample doesn't have an appropriate study" do

    sample = create(:sample)
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")])
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [open_study, managed_study])
    expect(Accession::Sample.new(sample)).to_not be_valid

  end

  it "should not be sent for accessioning if the sample doesn't have the required fields" do

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample)).to be_valid

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample)).to be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:gender)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:phenotype)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:donor_id)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    expect(Accession::Sample.new(sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    expect(Accession::Sample.new(sample)).to_not be_valid

  end

  it "an appropriate service should be chosen based on the associated study" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample).service).to eq(:ENA)

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample).service).to eq(:EGA)

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample).service).to be_nil

  end

  it "should have a name" do
    sample = create(:sample, name: "Sample_1-", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample).name).to eq("sample_666")

    sample = create(:sample, name: "Sample_1_", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_public_name)))
    expect(Accession::Sample.new(sample).name).to eq("sample_1_")

  end

  it "should have a common name and taxon id" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(sample).common_name).to eq(metadata[:sample_common_name])
    expect(Accession::Sample.new(sample).taxon_id).to eq(metadata[:sample_taxon_id])
  end
end