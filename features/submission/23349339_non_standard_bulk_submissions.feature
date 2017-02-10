@submission @bulk_submissions
Feature: Non-standard Bulk Submission files
  So that the bulk submission feature is more tolerant
  it should make fewer assumptions about csv structure
  it should detect the position of the header row
  and remove columns with no content.


  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have administrative role
    And I have an "active" study called "abc123_study"
    And I have a project called "Test project"
    And the study "abc123_study" has an asset group of 1 samples in "well" called "assetgroup123"
    And study "abc123_study" has assets registered
    When I go to the create bulk submissions page
    Then I should see "Bulk Submission New"

  Scenario: Uploading a file with an empty column
    When I upload a file with an empty column
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"

  Scenario: Uploading a file with a header not at row 0 or 1
    When I upload a file with a header at an unexpected location
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"

  Scenario: Uploading a file with a headerless column
    When I upload a file with a headerless columnn
    Then I should see "Row 2, column 4 contains data but no heading."
