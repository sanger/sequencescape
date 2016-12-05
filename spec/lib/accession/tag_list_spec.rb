require 'rails_helper'

RSpec.describe Accession::TagList, type: :model, accession: true do
  include SampleManifestExcel::Helpers

  let(:folder)      { File.join("spec", "data") }
  let(:yaml)        { load_file(folder, "accession_tags") }
  let(:tag_list)    { Accession::TagList.new(yaml) }
  let(:metadata)    { { sample_taxon_id: 1, sample_common_name: "A common name", donor_id: "1",
                        gender: "Unknown", phenotype: "Indescribeable", growth_condition: "No",
                        sample_public_name: "Sample 666", disease_state: "Awful" }}

  it "should have the correct number of tags" do
    expect(tag_list.count).to eq(yaml.count)
  end

  it "should be able to find a tag by its key" do
    expect(tag_list.find(yaml.keys.first.to_s).name).to eq(yaml.keys.first)
    expect(tag_list.find(yaml.keys.first.to_sym).name).to eq(yaml.keys.first)
    expect(tag_list.find(:dodgy_tag)).to be_nil
  end

  it "should pick out tags which are required for each service" do
    expect(tag_list.required_for(:ENA).count).to eq(2)
    expect(tag_list.required_for(:EGA).count).to eq(5)
  end

  it "should group the tags" do
    tags = tag_list.by_group
    expect(tags.count).to eq(3)
    expect(tags[:sample_name].count).to eq(2)
    expect(tags[:sample_attributes].count).to eq(3)
    expect(tags[:array_express].count).to eq(6)
  end

  it "#extract should create a new tag list with tags that have values" do
    sample = create(:sample,  sample_metadata: Sample::Metadata.new(metadata))
    extract = tag_list.extract(sample.sample_metadata)
    expect(extract.count).to eq(metadata.count)
    expect(extract.find(:sample_common_name).value).to eq("A common name")
  end

  it "should indicate whether service requirements are met" do
    sample = create(:sample,  sample_metadata: Sample::Metadata.new(metadata))
    extract = tag_list.extract(sample.sample_metadata)
    expect(extract.meets_service_requirements?(:ENA, tag_list)).to be_truthy
    expect(extract.meets_service_requirements?(:EGA, tag_list)).to be_truthy

    sample = create(:sample,  sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    extract = tag_list.extract(sample.sample_metadata)
    expect(extract.meets_service_requirements?(:ENA, tag_list)).to be_falsey
    expect(extract.meets_service_requirements?(:EGA, tag_list)).to be_falsey
  end

end