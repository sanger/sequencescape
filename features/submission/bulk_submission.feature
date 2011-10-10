@javascript @submission
Feature: Bulk Submission
  So that biological work can be requested
  in a large batch rather than separate 
  submissions which take a long time to do,
  Users with privileges should be able to submit a
  csv spreadsheet with multiple submissions


  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have administrative role
    And I have an "active" study called "abc123_study"
    And I have a project called "Test project"
    # And the study "abc123_study" has an asset group called "assetgroup123"
    And the study "abc123_study" has an asset group of 10 samples called "assetgroup123"
    # And I have a sample tube called "testing123" registered under study
    And study "abc123_study" has assets registered
   # And the sample tube "testing123" is in the asset group "assetgroup123"
    When I go to the study workflow page for "abc123_study"
    Then I should see "abc123_study"
    When I follow "Create Submission"
    Then I should see "use the bulk uploader"
    When I follow "Upload a bulk submission"
    Then I should see "Create a bulk submission"
   

  Scenario: Uploading a valid file with 1 submissions
    When I upload a file with valid data for 1 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"
    
  Scenario: Uploading a valid file with 2 submissions
    When I upload a file with valid data for 2 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"

  Scenario: Uploading an invalid file with 1 submissions
    When I upload a file with invalid data for 1 submissions
    Then I should see "There was a problem with your upload"
    
  Scenario: Uploading an invalid file with 2 submissions
    When I upload a file with invalid data for 2 submissions
    Then I should see "There was a problem with your upload"
    
  Scenario: Uploading an empty file
    When I upload an empty file
    Then I should see "was an empty file"
    