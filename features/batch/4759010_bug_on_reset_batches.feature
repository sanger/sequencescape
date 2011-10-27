@batch
Feature: Resetting a batch and creating an "identical" batch
  Background:
    Given sequencescape is setup for 4759010
    Given I am logged in as "John Smith"
    And I am an administrator

  Scenario: Reseting a batch and creating an "identical" batch
    Given a batch in "MX Library Preparation [NEW]" has been setup for feature 4759010
    When I go to the edit page for the last batch
    And I press "Reset"
    Then I should be on the "MX Library Preparation [NEW]" pipeline page

    When I select all requests
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"

    # "Start batch" page
    When I follow "Start batch"

    # "Tag groups" page
    When I press "Next step"

    # "Assign tags" page
    And I fill in "Multiplexed Library name" with "New Name"
    And I press "Next step"

    # "Initial QC" page 
    Then I should see "TASK DETAILS"
    And I press "Next step"
    And I should not see "Unable to find sequencing request"
