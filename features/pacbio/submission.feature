@pacbio @submission @pacbio_submission @barcode-service
Feature: Create a submission for the pacbio pipeline

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    Given I am on the show page for study "Test study"
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
    When I follow "Print worksheet"
    Then the PacBio sample prep worksheet should look like:
       | Well          | Name       | Required size | Complete? | Repaired? | Adapter ligated? | Clean up complete? | Exonnuclease cleanup | ng/ul | Fragment size | Volume |
       | DN1234567T:A1 | Sample_111 | 500           |           |           |                  |                    |                      |       |               |        |
       | DN1234567T:B1 | Sample_222 | 500           |           |           |                  |                    |                      |       |               |        |


  Scenario: When a sample fails dont enter number of SMRTcells and cancel sequencing request
    Given I have a PacBio Library Prep batch
    When I follow "DNA Template Prep Kit Box Barcode"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Sample Prep QC"
    When I select "Fail" from "QC PacBioLibraryTube 333"
    And I select "Pass" from "QC PacBioLibraryTube 444"
    And I press "Next step"
    Then the PacBioLibraryTube "333" should have 0 SMRTcells
    And the PacBioLibraryTube "444" should have 1 SMRTcells
    When I press "Release this batch"
    Then I should see "Batch released!"
    Then 1 PacBioSequencingRequests for "333" should be "cancelled"
    And the PacBioSamplePrepRequests for "DN1234567T:A1" should be "failed"





