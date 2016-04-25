@batch @javascript
Feature: Resetting a batch and creating an "identical" batch
  Background:
    Given sequencescape is setup for 4759010
    Given I am logged in as "John Smith"
    And I am an administrator

  Scenario: bug on reset batch
    Given a batch in "Illumina-B MX Library Preparation" has been setup for feature 4759010
    When I go to the edit page for the last batch
    And I press "Reset"
    And I accept the action
    Then I should be on the "Illumina-B MX Library Preparation" pipeline page

    When I check "Select Request Group 0"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"

    # "Start batch" page
    When I follow "Tag Groups"

    # "Tag groups" page
    When I press "Next step"

    # "Assign tags" page
    And I fill in "Multiplexed Library name" with "New Name"
    And I press "Next step"

    # "Initial QC" page
    Then I should see "TASK DETAILS"
    And I press "Next step"
    And I should not see "Unable to find sequencing request"
