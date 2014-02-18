@pacbio @submission @pacbio_submission @barcode-service
Feature: Create a submission for the pacbio pipeline

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    Given I am on the show page for study "Test study"
    Given the plate barcode webservice returns "99999"

  @worksheet @old_submission @wip
  Scenario Outline: Valid submission with different options
  Given study "Test study" has an asset group called "Test group b" with 1 wells
   When I have a "PacBio" submission with the following setup:
        |Study | Test study |
        | Project | Test project |
        | Asset Group | Test group b |
        | Insert size | <insert_size> |
        | Sequencing type | <sequencing_type> |
        | multiplier#2 |  <smart_cells_requested> |
    Given 1 pending delayed jobs are processed
    Then I should have <number_of_smart_cells> PacBioSequencingRequests
    Given I am on the show page for pipeline "PacBio Sample Prep"
    Then I should see "<sequencing_type>"
    And I should see "<insert_size>"
    When I check "Select SampleTube 111 for batch"
    When I press "Submit"
    When I follow "DNA Template Prep Kit Box Barcode"
    Given Well "1234567":"A1" has a PacBioLibraryTube "333"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    When I follow "Print worksheet"
    Then the PacBio sample prep worksheet should look like:
       | Well         | Name       | Required size | Complete? | Repaired? | Adapter ligated? | Clean up complete? | Exonnuclease cleanup | ng/ul | Fragment size | Volume |
       | DN1234567T:A1 | Sample_111 | <insert_size> |           |           |                  |                    |                      |       |               |        |
    Given I am on the homepage
    When I set PacBioLibraryTube "3980000333858" to be in freezer "PacBio sequencing freezer"
    Given I am on the show page for pipeline "PacBio Sequencing"
    Then I should see "<sequencing_type>"
    And I should see "<insert_size>"

    Examples:
      | sequencing_type | insert_size | number_of_smart_cells |
      | MagBead         | 250         | 1                     |
      | Standard        | 2000        | 2                     |
      | MagBead         | 500         | 1                     |
      | Standard        | 1000        | 2                     |
      | MagBead         | 6000        | 1                     |
      | Standard        | 8000        | 2                     |


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
       | DN1234567T:A1 | Sample_111 | 250           |           |           |                  |                    |                      |       |               |        |
       | DN1234567T:B1 | Sample_222 | 250           |           |           |                  |                    |                      |       |               |        |


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





