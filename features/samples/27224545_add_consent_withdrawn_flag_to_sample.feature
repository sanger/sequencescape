@sample
Feature: Patients should be able to withdraw consent
  So as to track withdraw of consent
  Samples should be able to be flagged as withdrawn
  This should be presented to downstream users

  Background:
    Given all of this is happening at exactly "2010-Sep-08 09:00:00+01:00"
    And I am an "Manager" user logged in as "user"
    And I have an active study called "Study A"
    And user "user" is a "manager" of study "Study A"
    And I have an "approved" project called "Project A"
    And project "Project A" has enforced quotas
    Given there are no samples
    And the study "Study A" has the sample "sample_withdrawn" in a sample tube and asset group
    And the study "Study A" has the sample "sample_okay" in a sample tube and asset group
    And the patient has withdrawn consent for "sample_withdrawn"

  Scenario: Withdrawn consent is presented downstream
    When I am on the samples page for study "Study A"
    Then I should see "Consent withdrawn" within ".withdrawn"
    And I should see "sample_withdrawn" within ".withdrawn"
    And I should not see "sample_okay" within ".withdrawn"
    When I am on the show page for sample "sample_okay"
    Then I should not see "Patient consent has been withdrawn for this sample."
    When I am on the show page for sample "sample_withdrawn"
    Then I should see "Patient consent has been withdrawn for this sample."

  Scenario: Withdrawn consent is visible in sample xml
    When I get the XML for the sample "sample_okay"
    Then the text of the as is XML element "//sample/consent_withdrawn" should be "false"
    When I get the XML for the sample "sample_withdrawn"
    Then the text of the as is XML element "//sample/consent_withdrawn" should be "true"

  @batch
  Scenario: Withdrawn consent is visible in batch xml
    Given the batch exists with ID 1
    And batch "1" in "Pulldown library preparation" has been setup with "sample_okay_group" for feature 27224545
    When I get the XML for the batch "1"
    Then the value of the "consent_withdrawn" attribute of the XML element "//batch/lanes/lane/library/sample" should be "false"

    Given the batch exists with ID 2
    And batch "2" in "Pulldown library preparation" has been setup with "sample_withdrawn_group" for feature 27224545
    When I get the XML for the batch "2"
    Then the value of the "consent_withdrawn" attribute of the XML element "//batch/lanes/lane/library/sample" should be "true"

  Scenario: Withdrawn consent is presented to the warehouse
    And I am using version "0_5" of a legacy API
    And the UUID for the sample "sample_withdrawn" is "00000000-1111-2222-4444-444444444444"
    And the UUID for the sample "sample_okay" is "00000000-1111-2222-4444-555555555555"
    And the sanger sample id for sample "00000000-1111-2222-4444-444444444444" is "1STDY123"
    And the sanger sample id for sample "00000000-1111-2222-4444-555555555555" is "1STDY124"

    When I GET the API path "/samples/00000000-1111-2222-4444-444444444444"
    And ignoring "id|updated_at" the JSON should be:
    """
      {
        "sample": {
          "uuid": "00000000-1111-2222-4444-444444444444",
          "name": "sample_withdrawn",
          "consent_withdrawn": true,
          "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-4444-444444444444/sample_tubes",

          "replicate": null,
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "empty_supplier_sample_name": false,
          "supplier_name": null,
          "updated_by_manifest": false,

          "created_at": "2010-09-08T09:00:00+01:00",
          "updated_at": "2010-09-08T09:00:00+01:00",
          "new_name_format": true,

          "id": 1
        },"lims":"SQSCP"
      }
    """
    When I GET the API path "/samples/00000000-1111-2222-4444-555555555555"
    And ignoring "id|updated_at" the JSON should be:
    """
      {
        "sample": {
          "uuid": "00000000-1111-2222-4444-555555555555",
          "name": "sample_okay",
          "consent_withdrawn": false,
          "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-4444-555555555555/sample_tubes",

          "replicate": null,
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "empty_supplier_sample_name": false,
          "supplier_name": null,
          "updated_by_manifest": false,

          "created_at": "2010-09-08T09:00:00+01:00",
          "updated_at": "2010-09-08T09:00:00+01:00",
          "new_name_format": true,

          "id": 1
        },"lims":"SQSCP"
      }
    """

  @submission
  Scenario: Submissions can not be created containing withdrawn samples
  Given I try to create a "Illumina-C - Multiplexed Library Creation - Single ended sequencing" order with the following setup:
    | Project                     | Project A              |
    | Study                       | Study A                |
    | Asset Group                 | sample_withdrawn_group |
    | Fragment size required from | 300                    |
    | Fragment size required to   | 400                    |
    | Read length                 | 108                    |
  Then the order should be invalid
  And the order should have errors
  And the last error should contain "Samples in this submission have had patient consent withdrawn: sample_withdrawn"
  When I try to save the order
  Then the order should not be built
  Given I try to create a "Illumina-C - Multiplexed Library Creation - Single ended sequencing" order with the following setup:
    | Project                     | Project A              |
    | Study                       | Study A                |
    | Asset                       | sample_withdrawn_tube  |
    | Fragment size required from | 300                    |
    | Fragment size required to   | 400                    |
    | Read length                 | 108                    |
  Then the order should be invalid
  And the order should have errors
  And the last error should contain "Samples in this submission have had patient consent withdrawn: sample_withdrawn"
  When I try to save the order
  Then the order should not be built
  Given I try to create a "Illumina-C - Multiplexed Library Creation - Single ended sequencing" order with the following setup:
    | Project                     | Project A              |
    | Study                       | Study A                |
    | Asset Group                 | sample_okay_group |
    | Fragment size required from | 300                    |
    | Fragment size required to   | 400                    |
    | Read length                 | 108                    |
  Then the order should be valid
  And the order should not have errors
  When I try to save the order
  Then the order should be built
  Given I try to create a "Illumina-C - Multiplexed Library Creation - Single ended sequencing" order with the following setup:
    | Project                     | Project A              |
    | Study                       | Study A                |
    | Asset                       | sample_okay_tube       |
    | Fragment size required from | 300                    |
    | Fragment size required to   | 400                    |
    | Read length                 | 108                    |
  Then the order should be valid
  And the order should not have errors
  When I try to save the order
  Then the order should be built
