@pacbio @pacbio_reference_sequence @reference_genome @barcode-service @secondary_analysis
Feature: Display secondary analysis details in the sample sheet

  Background:
    Given I am a "manager" user logged in as "user"
      And I have a project called "Test project"

      And I have an active study called "Test study"
      And I have a sample tube "111" in study "Test study" in asset group "Test study group"
      And the reference genome "Mouse" exists
      And the reference genome "Human" exists
      And the reference genome "Homo Sapien" exists
      And I am on the show page for study "Test study"
      And the plate barcode webservice returns "99999"


  # remove this test when the secondary analysis is reenabled on the instrument
  Scenario: 1 Sample has a reference genome, the other has none set, but we set it then
    And the plate barcode webservice returns "99998"
    Given the sample in tube "111" has a reference genome of "Human"
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference |
      |  333 | Test study | Human     |
      |  444 | Test study |           |
    Then the default protocols should be:
      | Protocol |
      | Human    |
      |          |
    When I select "Mouse" from "Protocol for Tube 444"
      And I press "Next step"
    Then Library tube "333" should have protocol "Human"
      And Library tube "444" should have protocol "Mouse"
    When I press "Next step"
      And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name   | Secondary Analysis Protocol | Secondary Analysis Parameters |
      | A01      | DN1234567T-A1 |                             |                               |
      | B01      | DN1234567T-B1 |                             |                               |


  # Secondary analysis has been disabled. Reenable these tests when its turned back on
  @wip
  Scenario: 1 Sample has a reference genome, the other has none set, but we set it then
    Given the sample in tube "111" has a reference genome of "Human"
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference |
      |  333 | Test study | Human     |
      |  444 | Test study |           |
    Then the default protocols should be:
      | Protocol |
      | Human    |
      |          |
    When I select "Mouse" from "Protocol for Tube 444"
      And I press "Next step"
    Then Library tube "333" should have protocol "Human"
      And Library tube "444" should have protocol "Mouse"
    When I press "Next step"
      And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name | Secondary Analysis Protocol |
      |  A01     | Sample_111  | Human                       |
      |  A02     | Sample_222  | Mouse                       |

  # Secondary analysis has been disabled. Reenable these tests when its turned back on
  @wip
  Scenario Outline: Study has a reference genome with invalid characters
    Given the reference genome "<reference>" exists
    Given the study "Test study" has a reference genome of "<reference>"
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference   |
      |  333 | Test study | <reference> |
      |  444 | Test study | <reference> |
    Then the default protocols should be:
      | Protocol |
      | <reference>    |
      | <reference>    |
    When I press "Next step"
      And I press "Next step"
    Then Library tube "333" should have protocol "<reference>"
      And Library tube "444" should have protocol "<reference>"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Secondary Analysis Protocol |
      | A01      | <protocol>                  |
      | A02      | <protocol>                  |

    Examples:
      | reference     | protocol      |
      | (abc)         | _abc_         |
      | abc efg-(89)= | abc_efg__89__ |
      | ABC*123_!     | ABC_123__     |
