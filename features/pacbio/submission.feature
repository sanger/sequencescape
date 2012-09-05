@pacbio @submission @pacbio_submission @barcode-service
Feature: Create a submission for the pacbio pipeline

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    Given I am on the show page for study "Test study"
    Given the plate barcode webservice returns "99999"

  @worksheet @old_submission @wip
  Scenario Outline: Valid submission with different options
   When I have a "PacBio" submission with the following setup:
        |Study | Test study |
        | Project | Test project |
        | Asset Group | Test study group |
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
    When I follow "Start batch"
    Given SampleTube "111" has a PacBioLibraryTube "333"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    When I fill in "Number of SMRTcells for PacBioLibraryTube 333" with "15"
    And I press "Next step"
    When I press "Release this batch"
    When I follow "Print worksheet"
    Then the PacBio sample prep worksheet should look like:
       | Barcode | Name       | Required size | Complete? | Repaired? | Adapter ligated? | Clean up complete? | Exonnuclease cleanup | ng/ul | Fragment size | Volume |
       | 111     | Sample_111 | <insert_size> |           |           |                  |                    |                      |       |               |        |
    Given I am on the homepage
    When I set PacBioLibraryTube "3980000333858" to be in freezer "PacBio sequencing freezer"
    Given I am on the show page for pipeline "PacBio Sequencing"
    Then I should see "<sequencing_type>"
    And I should see "<insert_size>"

    Examples:
      | sequencing_type | insert_size | number_of_smart_cells |
      | Strobe          | 250         | 1                     |
      | Standard        | 2000        | 2                     |
      | Circular        | 200         | 3                     |
      | Strobe          | 500         | 1                     |
      | Standard        | 1000        | 2                     |
      | Circular        | 4000        | 3                     |
      | Strobe          | 6000        | 1                     |
      | Standard        | 8000        | 2                     |
      | Circular        | 10000       | 3                     |


  Scenario: No kit number entered
    Given I have a PacBio Sample Prep batch
    When I follow "Start batch"
    When I fill in "DNA Template Prep Kit Box Barcode" with ""
    And I press "Next step"
    Then I should see "Please enter a Kit Barcode"


  @worksheet
  Scenario: Sample Sheet
    Given I have a PacBio Sample Prep batch
    When I follow "Print worksheet"
    Then the PacBio sample prep worksheet should look like:
       | Barcode | Name       | Required size | Complete? | Repaired? | Adapter ligated? | Clean up complete? | Exonnuclease cleanup | ng/ul | Fragment size | Volume |
       | 111     | Sample_111 | 250           |           |           |                  |                    |                      |       |               |        |
       | 222     | Sample_222 | 250           |           |           |                  |                    |                      |       |               |        |


  Scenario: When a sample fails dont enter number of SMRTcells and cancel sequencing request
    Given I have a PacBio Sample Prep batch
    When I follow "Start batch"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    Then I should see "Sample Prep QC"
    When I select "Fail" from "QC PacBioLibraryTube 333"
    And I select "Pass" from "QC PacBioLibraryTube 444"
    And I press "Next step"
    Then I should see "Number of SMRTcells that can be made"
    Then I should not see "Number of SMRTcells for PacBioLibraryTube 333"
    And I should see "Number of SMRTcells for PacBioLibraryTube 444"
    When I fill in "Number of SMRTcells for PacBioLibraryTube 444" with "1"
    And I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"
    Then 1 PacBioSequencingRequests for "333" should be "cancelled"
    And the PacBioSamplePrepRequests for "111" should be "failed"

  Scenario Outline: The number of SMRTcells that can be made is less than the number requested
   When I have a "PacBio" submission with the following setup:
        |Study | Test study |
        | Project | Test project |
        | Asset Group | Test study group |
        | Insert size | 250 |
        | Sequencing type | Standard |
        | multiplier#2 |  <smart_cells_requested> |
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "PacBio Sample Prep"
    When I check "Select SampleTube 111 for batch"
    When I press "Submit"
    Given SampleTube "111" has a PacBioLibraryTube "333"
    When I follow "Start batch"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    When I fill in "Number of SMRTcells for PacBioLibraryTube 333" with "<actual_smart_cells_available>"
    And I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"
    Then <num_cancelled_requests> PacBioSequencingRequests for "333" should be "cancelled"
    Examples:
      | smart_cells_requested | actual_smart_cells_available | num_cancelled_requests |
      | 1                     | 1                            | 0                      |
      | 1                     | 0                            | 1                      |
      | 1                     | 2                            | 0                      |
      | 2                     | 1                            | 1                      |
      | 10                    | 3                            | 7                      |

  Scenario Outline: Invalid input into the SMRTcells field
    Given I have a PacBio Sample Prep batch
    When I follow "Start batch"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    Then I should see "Sample Prep QC"
    When I select "Pass" from "QC PacBioLibraryTube 333"
    And I press "Next step"
    When I fill in "Number of SMRTcells for PacBioLibraryTube 333" with "<actual_smart_cells_available>"
    And I press "Next step"
    Then I should see "Invalid SMRTcell value"
    Then I should see "Number of SMRTcells that can be made"
    Examples:
      | actual_smart_cells_available |
      | -1                           |
      | 1.5                          |
      | 1k                           |
      | one                          |
      |                              |





