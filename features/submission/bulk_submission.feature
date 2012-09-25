@javascript @submission @bulk_submissions
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
    And the study "abc123_study" has an asset group of 10 samples in "well" called "assetgroup123"
    # And I have a sample tube called "testing123" registered under study
    And study "abc123_study" has assets registered
   # And the sample tube "testing123" is in the asset group "assetgroup123"
    When I go to the create bulk submissions page
    Then I should see "Create a bulk submission"

  Scenario: Uploading a valid file with 1 submission but a deprecated template
    # When I upload a file with valid data for 1 submissions but deprecated template
    When I upload a file with deprecated data for 1 submissions
    Then I should see "Template: 'Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' is deprecated and no longer in use."


  Scenario: Uploading a valid file with 1 submission
    When I upload a file with valid data for 1 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"
    And the preordered quota for project "Test project" should be:
         | RequestType                 | preordered |
         | Cherrypicking for Pulldown  | 10         |
         | Pulldown WGS                | 10         |
         | HiSeq Paired end sequencing | 1          |

  Scenario: Uploading a valid file where the project has no quotas but quota is enforced
    Given project "Test project" has enforced quotas
      And project "Test project" has no quotas
    When I upload a file with valid data for 1 submissions
    Then I should see "There was a quota problem"

  Scenario: Uploading a valid file with bait library specified should set the bait library name
    Given I have a well called "testing123"
      And the sample in well "testing123" is registered under the study "abc123_study"
    When I upload a file with 2 valid SC submissions
    Then I should see "Your submissions:"
     And there should be an order with the bait library name set to "Bait library 1"
     And there should be an order with the bait library name set to "Bait library 2"

  Scenario: Uploading a valid file where there is insufficent quota
    Given project "Test project" has enforced quotas
      And project "Test project" has 10 units of "Cherrypicking for Pulldown" quota
      And project "Test project" has 2 units of "Pulldown WGS" quota
      And project "Test project" has 1 units of "HiSeq Paired end sequencing" quota
    When I upload a file with valid data for 1 submissions
    Then I should see "Insufficient quota for Pulldown WGS"

  @this
  Scenario: Uploading a valid file with 2 submissions
    When I upload a file with valid data for 2 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"

  Scenario: Uploading an invalid file with 1 submissions
    When I upload a file with invalid data for 1 submissions
    Then I should see "Cannot find user"
    Then there should be no submissions

  Scenario: Uploading an invalid file with 2 submissions
    When I upload a file with invalid data for 2 submissions
    Then I should see "There was a problem on row(s)"
    Then there should be no submissions

  Scenario: Uploading an invalid file with 2 submissions
    When I upload a file with 1 invalid submission and 1 valid submission
    Then I should see "There was a problem on row(s)"
    Then there should be no submissions

  Scenario: Uploading an empty file
    When I upload an empty file
    Then I should see "The supplied file was empty"

  Scenario: Uploading a file without a (valid) header row
    When I upload a file with an invalid header row
    Then I should see "The supplied file does not contain a valid header row"
    Then there should be no submissions

  Scenario: Leaving the file field blank
    When I submit an empty form
    Then I should see "can't be blank"

