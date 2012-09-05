@submission @sanger_sample_id @wip @old_submission
Feature: Create a submission based on the sanger_sample_id

  Background:
    Given I am a "administrator" user logged in as "user"
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    Given I have a plate in study "Test study" with samples with known sanger_sample_ids
    Given I am on the show page for study "Test study"
    When I follow "Create Submission"
    When I select "DNA QC" from "Template"
    And I press "Next"
    When I select "Test study" from "Select a study"
    When I select "Test project" from "Select a financial project"

  Scenario: Submission with sanger sample ids and sample names for different samples
    When I fill in "sample_names" with multiline text
    """
    Sample_1
    Sample_2
    ABC_3
    ABC_4
    """
    And I create the order and submit the submission
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "DNA QC"
    Then the pipeline inbox should be:
     | Barcode    | Wells | Study      |
     | DN1234567T | 4     | Test study |

  Scenario: Submission with sanger sample ids and sample names where both refer to the same samples
    When I fill in "sample_names" with multiline text
    """
    Sample_1
    Sample_2
    ABC_1
    ABC_2
    """
    And I create the order and submit the submission
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "DNA QC"
    Then the pipeline inbox should be:
     | Barcode    | Wells | Study      |
     | DN1234567T | 2     | Test study |

  # spaces and tabs at the end of the lines below are deliberate
  @spaces
  Scenario: Sample names and ids with spaces/tab at the end
    When I fill in "sample_names" with multiline text
    """
    Sample_1
    Sample_2
    ABC_3
    ABC_4
    """
    And I create the order and submit the submission
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "DNA QC"
    Then the pipeline inbox should be:
     | Barcode    | Wells | Study      |
     | DN1234567T | 4     | Test study |
