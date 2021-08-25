Feature: Resetting batches and their requests across the various pipelines
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario:

    And I have a batch with 5 requests for the "Cherrypick" pipeline
    And the batch and all its requests are pending

    Given I am on the "Cherrypick" pipeline page
    When I follow "View pending batch 1"
    Then I should see "Fail batch or requests Batches can not be failed when pending"
    When I follow "Select Plate Template"
    And I follow "Fail batch"
    And I check "Remove request" for 1 to 5
    And I select "Other" from "Select failure reason"
    And I press "Fail selected requests"
    Then I should see "removed."

    Then the 5 requests should be in the "Cherrypick" pipeline inbox
