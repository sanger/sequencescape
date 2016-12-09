require 'rails_helper'

RSpec.describe Accession::Sample, type: :model, accession: true do

  include SampleManifestExcel::Helpers

  let(:folder)          { File.join("spec", "data") }
  let(:yaml)            { load_file(folder, "accession_tags") }
  let(:tag_list)        { Accession::TagList.new(yaml) }

  it "should not be sent for accessioning if the sample has already been accessioned" do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_ebi_accession_number: "ENA123"))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid
  end

  it "should not be sent for accessioning if the sample doesn't have an appropriate study" do
    expect(Accession::Sample.new(tag_list, create(:sample))).to_not be_valid
    expect(Accession::Sample.new(tag_list, create(:sample, studies: [create(:open_study)]))).to_not be_valid

    sample = create(:sample, studies: [create(:open_study, accession_number: "ENA123"), create(:managed_study, accession_number: "ENA123")])
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

  end

  it "should not be sent for accessioning if the sample doesn't have the required fields" do

    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_common_name: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, gender: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, phenotype: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, donor_id: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_common_name: nil))
    expect(Accession::Sample.new(tag_list, sample)).to_not be_valid

  end

  it "an appropriate service should be chosen based on the associated study" do
    sample = create(:sample_for_accessioning_with_open_study)
    expect(Accession::Sample.new(tag_list, sample).service).to be_ena

    sample = create(:sample_for_accessioning_with_managed_study)
    expect(Accession::Sample.new(tag_list, sample).service).to be_ega

    sample = create(:sample, studies: [create(:open_study)])
    expect(Accession::Sample.new(tag_list, sample).service).to_not be_valid

  end

  it "should have a name and a title" do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: "Sample 666"))
    accession_sample = Accession::Sample.new(tag_list, sample)
    expect(accession_sample.name).to eq("sample_666")
    expect(accession_sample.title).to eq("Sample 666")

    sample = create(:sample_for_accessioning_with_open_study, name: "Sample_1-", sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: nil))
    accession_sample = Accession::Sample.new(tag_list, sample)
    expect(accession_sample.name).to eq("sample_1_")
    expect(accession_sample.title).to eq(sample.sanger_sample_id)
  end

  it "should create some xml" do
    accession_sample = Accession::Sample.new(tag_list, create(:sample_for_accessioning_with_open_study))
    xml = accession_sample.to_xml
    expect(xml).to include(accession_sample.ebi_alias)
    expect(xml).to include(accession_sample.title)

    accession_sample.tags.by_group.each do |k, group|
      group.each do |tag|
        expect(xml).to include((k == :array_express) ? tag.array_express_label : tag.label)
        expect(xml).to include(tag.value)
      end
    end

    accession_sample = Accession::Sample.new(tag_list, create(:sample_for_accessioning_with_managed_study))
    xml = accession_sample.to_xml
    accession_sample.tags.by_group[:array_express].each do |tag|
      expect(xml).to_not include(tag.array_express_label)
    end
  end


end