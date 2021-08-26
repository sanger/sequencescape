@pipeline @batch
Feature: Pipeline navigation
  Background:
    Given I am a "administrator" user logged in as "user"

  Scenario: Batch page
    Given I have a batch in "Cherrypick"
    Given I on batch page
    Then I should see "Edit batch"
    Then I should see "Select Plate Template"
    Then I should see "Print worksheet"

  Scenario: Creating a batch removes the request from the inbox
    Given I have a request for "Cluster formation PE"
    Given I am on the show page for pipeline "Cluster formation PE"
    When I check request 1
    When I press the first "Submit"

    When I am on the show page for pipeline "Cluster formation PE"
    Then the requests from "Cluster formation PE" batches should not be in the inbox

  Scenario: a user logs into the system
    Given I have a batch in "Cluster formation PE"
    Given I have a request for "Cluster formation PE"
    Given I am on the show page for pipeline "Cluster formation PE"
    Then I should see "Submission ID"
    Then I should see "Last 5"
    Then I should see "View batch"
    When I check request 1
    When I press the first "Submit"
    Then I should see "Edit batch"
    Then I should see "Specify Dilution Volume"
    Then I should see "Print worksheet"
