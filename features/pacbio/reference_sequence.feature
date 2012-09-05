@pacbio @pacbio_reference_sequence @reference_genome @barcode-service
Feature: Handle reference sequences and protocols

  Background:
    Given I am a "manager" user logged in as "user"
      And I have a project called "Test project"
      And project "Test project" has enough quotas
      And I have an active study called "Test study"
      And I have a sample tube "111" in study "Test study" in asset group "Test study group"
      And the reference genome "Mouse" exists
      And the reference genome "Human" exists
      And the reference genome "Homo Sapien" exists
      And I am on the show page for study "Test study"
      And the plate barcode webservice returns "99999"

  Scenario: 1 Sample has a reference genome, the other has none set
    Given the sample in tube "111" has a reference genome of "Homo Sapien"
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference   | Common Name | Taxon | Strain |
      |  333 | Test study | Homo Sapien | Homo Sapien | 9606  |        |
      |  444 | Test study |             | Flu         | 123   | H1N1   |
    Then the default protocols should be:
      | Protocol      |
      | Homo_Sapien   |
      |               |
    When I press "Next step"
    Then I should see "All samples must have a protocol selected"

  Scenario: Both Study and Sample have different reference genomes
    Given the study "Test study" has a reference genome of "Mouse"
    Given the sample in tube "111" has a reference genome of "Human"
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference |
      |  333 | Test study | Human     |
      |  444 | Test study | Mouse     |
    Then the default protocols should be:
      | Protocol |
      | Human    |
      | Human    |
    When I press "Next step"
    Then Library tube "333" should have protocol "Human"
      And Library tube "444" should have protocol "Mouse"

  Scenario: No reference genome set for either sample
    Given I have progressed to the Reference Sequence task
    Then the sample reference sequence table should look like:
      | Tube | Study      | Reference |
      |  333 | Test study |           |
      |  444 | Test study |           |
    Then the default protocols should be:
      | Protocol |
      |          |
      |          |
    When I select "Human" from "Protocol for Tube 333"
      And I select "Human" from "Protocol for Tube 444"
      And I press "Next step"
    Then Library tube "333" should have protocol "Human"
      And Library tube "444" should have protocol "Human"


