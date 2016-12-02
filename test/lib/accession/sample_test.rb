require 'test_helper'

class SampleTest < ActiveSupport::TestCase

  attr_reader :metadata, :open_study, :managed_study

  def setup
    @metadata = { sample_taxon_id: 1, sample_common_name: "A common name", 
                  gender: "Unknown", phenotype: "Indescribeable", donor_id: 1,
                  sample_public_name: "Sample 666", disease_state: "Awful" }
    @open_study = create(:open_study, accession_number: "ENA123")
    @managed_study = create(:managed_study, accession_number: "ENA123")
  end

  test "should be sent for accessioning if the sample is valid" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    assert Accession::Sample.new(sample).valid?
  end

  test "should not be sent for accessioning if the sample already has an accession number" do
    sample = create(:sample, studies: [create(:study)], sample_metadata: Sample::Metadata.new(sample_ebi_accession_number: "ENA123"))
    refute Accession::Sample.new(sample).valid?
  end

  test "should not be sent for accessioning if the sample doesn't have an appropriate study" do

    sample = create(:sample)
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")])
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [open_study, managed_study])
    refute Accession::Sample.new(sample).valid?

  end

  test "should not be sent for accessioning if the sample doesn't have the required fields" do

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    assert Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    assert Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:gender)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:phenotype)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:donor_id)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_taxon_id)))
    refute Accession::Sample.new(sample).valid?

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_common_name)))
    refute Accession::Sample.new(sample).valid?

  end

  test "an appropriate service should be chosen based on the associated study" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    assert_equal :ENA, Accession::Sample.new(sample).service

    sample = create(:sample, studies: [managed_study], sample_metadata: Sample::Metadata.new(metadata))
    assert_equal :EGA, Accession::Sample.new(sample).service

    sample = create(:sample, studies: [create(:open_study, name: "Study 1")], sample_metadata: Sample::Metadata.new(metadata))
    refute Accession::Sample.new(sample).service

  end

  test "should have a name" do
    sample = create(:sample, name: "Sample_1-", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    assert_equal "sample_666", Accession::Sample.new(sample).name

    sample = create(:sample, name: "Sample_1_", studies: [open_study], sample_metadata: Sample::Metadata.new(metadata.except(:sample_public_name)))
    assert_equal "sample_1_", Accession::Sample.new(sample).name

  end

  test "should have a common name and taxon id" do
    sample = create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata))
    assert_equal metadata[:sample_common_name], Accession::Sample.new(sample).common_name
    assert_equal metadata[:sample_taxon_id], Accession::Sample.new(sample).taxon_id
  end

end