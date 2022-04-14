@pacbio @submission @pacbio_submission @barcode-service
Feature: Create a submission for the pacbio pipeline

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"
    Given I have an active study called "Test study"
    Given the plate barcode webservice returns "99999"

  Scenario: No kit number entered
    Given I have a PacBio Library Prep batch
    When I follow "DNA Template Prep Kit Box Barcode"
    When I fill in "DNA Template Prep Kit Box Barcode" with ""
    And I press "Next step"
    Then I should see "Please enter a Kit Barcode"


  @worksheet
  Scenario: Sample Sheet
    Given I have a PacBio Library Prep batch
    When I follow "Print sample prep worksheet"
    Then the PacBio sample prep worksheet should look like:
       | Well          | Name       | Required size | Complete? | Repaired? | Adapter ligated? | Clean up complete? | Exonnuclease cleanup | ng/ul | Fragment size | Volume |
       | SQPD-1234567:A1 | Sample_A1 | 500           |           |           |                  |                    |                      |       |               |        |
       | SQPD-1234567:B1 | Sample_B1 | 500           |           |           |                  |                    |                      |       |               |        |


  Scenario: When a sample fails dont enter number of SMRTcells and cancel sequencing request
    Given I have a PacBio Library Prep batch
    When I follow "DNA Template Prep Kit Box Barcode"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Sample Prep QC"
    When I select "Fail" from "QC PacBioLibraryTube NT333U"
    And I select "Pass" from "QC PacBioLibraryTube NT444D"
    And I press "Next step"
    Then the PacBioLibraryTube "NT333" should have 0 SMRTcells
    And the PacBioLibraryTube "NT444" should have 1 SMRTcells
    When I press "Release this batch"
    Then I should see "Batch released!"
    Then 1 PacBioSequencingRequests for "NT333" should be "cancelled"
    And the PacBioSamplePrepRequests for "SQPD-1234567:A1" should be "failed"





