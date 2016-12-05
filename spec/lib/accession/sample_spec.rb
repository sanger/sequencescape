require 'rails_helper'

RSpec.describe Accession::Sample, type: :model, accession: true do

  include SampleManifestExcel::Helpers

  let(:folder)          { File.join("spec", "data") }
  let(:yaml)            { load_file(folder, "accession_tags") }
  let(:tag_list)        { Accession::TagList.new(yaml) }
  let(:metadata)        { { sample_taxon_id: 1, sample_common_name: "A common name", 
                          gender: "Unknown", phenotype: "Indescribeable", donor_id: 1,
                          sample_public_name: "Sample 666", disease_state: "Awful" } }
  let!(:open_study)     { create(:open_study, accession_number: "ENA123") }
  let!(:managed_study)  { create(:managed_study, accession_number: "ENA123") }

  it "should be sent for accessioning if the sample is valid" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample)).to be_valid
  end

  it "should not be sent for accessioning if the sample has already been accessioned" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.merge(sample_ebi_accession_number: "ENA123")))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid
  end

  it "should not be sent for accessioning if the sample doesn't have an appropriate study" do

    sample = create(:sample)
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")])
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [open_study, managed_study])
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

  end

  it "should not be sent for accessioning if the sample doesn't have the required fields" do

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample)).to be_valid

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample)).to be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:gender)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:phenotype)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:donor_id)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

  end

  it "an appropriate service should be chosen based on the associated study" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample).service).to eq(:ENA)

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample).service).to eq(:EGA)

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample).service).to be_nil

  end

  it "should have a name" do
    sample = create(:sample, name: "Sample_1-", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample).name).to eq("sample_666")

    sample = create(:sample, name: "Sample_1_", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_public_name)))
    expect(Accession::Sample.new(tag_list, sample).name).to eq("sample_1_")

  end

  it "should have a title" do
    sample = create(:sample, name: "Sample1", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    expect(Accession::Sample.new(tag_list, sample).title).to eq("Sample 666")

    sample = create(:sample, name: "Sample2", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_public_name)))
    expect(Accession::Sample.new(tag_list, sample).title).to eq(sample.sanger_sample_id)

  end

  it "should create some xml" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    accession_sample = Accession::Sample.new(tag_list, sample)

    xml = accession_sample.to_xml
    expect(xml).to include(accession_sample.alias)
    expect(xml).to include(accession_sample.title)

    accession_sample.tags.by_group.each do |k, group|
      group.each do |tag|
        expect(xml).to include((k == :array_express) ? tag.array_express_label : tag.label)
        expect(xml).to include(tag.value)
      end
    end

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    accession_sample = Accession::Sample.new(tag_list, sample)
    xml = accession_sample.to_xml
    accession_sample.tags.by_group[:array_express].each do |tag|
      expect(xml).to_not include(tag.array_express_label)
    end
  end


end