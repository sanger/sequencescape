@pipeline @batch
Feature: Pipeline navigation
  Background:
    Given I am a "administrator" user logged in as "user"

  Scenario: Batch page
    Given I have a batch in "Illumina-C Library preparation"
    Given I on batch page
    Then I should see "Edit batch"
    Then I should see "Start batch"
    Then I should see "Print worksheet"

  Scenario: Make training batch
    Given I have a batch in "Cluster formation SE"
    Given I have a control called "PhiX" for "Cluster formation SE"
    Given I am on the show page for pipeline "Cluster formation SE"
    When I follow "Make training batch"
    When I press "Create batch"
    Then I should see "Edit batch"

  Scenario: Creating a batch removes the request from the inbox
    Given I have a request for "Illumina-C Library preparation"
    Given I am on the show page for pipeline "Illumina-C Library preparation"
    When I check request "1" for pipeline "Illumina-C Library preparation"
    When I press "Submit"

    When I am on the show page for pipeline "Illumina-C Library preparation"
    Then the requests from "Illumina-C Library preparation" batches should not be in the inbox

  Scenario: a user logs into the system
    Given I have a batch in "Illumina-C Library preparation"
    Given I have a request for "Illumina-C Library preparation"
    Given I am on the show page for pipeline "Illumina-C Library preparation"
    Then I should see "Submission ID"
    Then I should see "Last 5"
    Then I should see "View batch"
    When I check request "1" for pipeline "Illumina-C Library preparation"
    When I press "Submit"
    Then I should see "Edit batch"
    Then I should see "Start batch"
    Then I should see "Print worksheet"

    #completing the batch
    When I follow "Start batch"
    And I press "Next step"
    # This is only here to check that this is working and there is nothing after here.
