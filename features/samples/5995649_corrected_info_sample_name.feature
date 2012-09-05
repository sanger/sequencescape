Feature: Show user correct sample name structure

  Background:
     Given I am logged in as "user"
     And I have a sample called "sample_test" with metadata

  Scenario: ....
    Given I am on the show page for sample "sample_test"
    Then I should see "Sample names need to be unique and can only contain letters, numbers, underscores and hyphens."
  And I should not see "underscores and hyphens are not allowed"

