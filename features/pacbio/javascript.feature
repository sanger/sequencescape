@pacbio @submission @barcode-service @sample_validation_service @javascript
Feature: Push samples through the PacBio pipeline with javascript

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    Given I am on the show page for study "Test study"

    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    Given the "1D Tube" barcode printer "xyz" exists
    Given the "96 Well Plate" barcode printer "xyz" exists
    And the plate barcode webservice returns "99999"
    Given the sample validation webservice returns "true"
      And the reference genome "Mouse" exists
    Given the study "Test study" has a reference genome of "Mouse"

  Scenario: Enough SMRTcells requested to cover multiple wells
    Given sample tube "111" is part of study "Test study"
    Given I have a "PacBio" submission with the following setup:
       | Project         | Test project     |
       | Study           | Test study       |
       | Asset Group     | Test study group |
       | Insert size     | 2000             |
       | Sequencing type | Standard         |
       | multiplier#2    | 22               |
    #When I follow "Create Submission"
    #When I select "PacBio" from "Template"
    #And I press "Next"
    #When I select "Test study" from "Select a study"
    #When I select "Test project" from "Select a financial project"
    #And I select "Test study group" from "Select a group to submit"
    #And I select "2000" from "Insert size"
    #And I select "Standard" from "Sequencing type"
    #And I fill in "Multiplier for step 2" with "22"
    #And I create the order and submit the submission
    Given 1 pending delayed jobs are processed

    Given I am on the show page for pipeline "PacBio Sample Prep"
    When I check "Select SampleTube 111 for batch"
    When I press "Submit"
    When I follow "Start batch"
    Given SampleTube "111" has a PacBioLibraryTube "333"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    When I fill in "Number of SMRTcells for PacBioLibraryTube 333" with "15"
    And I press "Next step"
    When I press "Release this batch"
    When I set PacBioLibraryTube "3980000333858" to be in freezer "PacBio sequencing freezer"
    Given I am on the show page for pipeline "PacBio Sequencing"
    When I check "Select Request Group 0"
    And I press "Submit"
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I fill in "Movie length for 333" with "12"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
    And the plate layout should look like:
      | 1        | 2        | 3        | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      | Tube 333 | Tube 333 | Tube 333 |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
      |          |          |          |   |   |   |   |   |   |    |    |    |
    And I press "Next step"
    Then I should see "Validate Sample Sheet"
    And I should see "Download Sample Sheet"
    And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name | CP Parameters                                               |
      | A01      | Sample_111  |  AcquisitionTime=12\|InsertSize=2000\|NumberOfCollections=7 |
      | A02      | Sample_111  |  AcquisitionTime=12\|InsertSize=2000\|NumberOfCollections=7 |
      | A03      | Sample_111  |  AcquisitionTime=12\|InsertSize=2000\|NumberOfCollections=1 |
    When I press "Release this batch"
    Then I should see "Batch released!"
    When I follow "Print plate labels"
    Then I should see "99999"
    When I press "Print labels"
    Then I should see "Your labels have been printed"

  Scenario: Print out the library tube barcodes
    Given I have a PacBio Sample Prep batch
    When I follow "Print labels"
    When I select "xyz" from "Print to"
    When I press "Print labels"
    Then I should see "Your labels have been printed to xyz."
