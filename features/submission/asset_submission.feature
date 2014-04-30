@submission @asset @request @javascript
Feature: Submitting an asset directly for a request
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have a project called "Testing the submission of an asset"

    Given I have an "active" study called "Testing submission of an asset"
    And the study "Testing submission of an asset" has a library tube called "library tube 1"

  Scenario Outline: Submission succeeds
    Given the library tube "library tube 1" has been involved in a "<sequencing type>" request within the study "Testing submission of an asset" for the project "Testing the submission of an asset"

    Given I am on the show page for library tube "library tube 1"
    When I follow "Request additional sequencing"
    And I select "<sequencing type>" from "Request type"
    And I select "Testing submission of an asset" from "Study"
    When I select "Testing the submission of an asset" from "Project"
    And I fill in "Fragment size required (from)" with "100" for the "<sequencing type>" request type
    And I fill in "Fragment size required (to)" with "200" for the "<sequencing type>" request type
    And I select "<read length>" from "Read length" for the "<sequencing type>" request type
    And I press "Create"
    Then I should see "Created request"

    # Ensure that the submission can be processed validly
    Given all pending delayed jobs are processed
    Then the library tube "library tube 1" should have 2 "<sequencing type>" requests

    Examples:
      | sequencing type                        | read length |
      | Illumina-C Single ended sequencing     | 76          |
      | Illumina-C Paired end sequencing       | 76          |
      | Illumina-C HiSeq Paired end sequencing | 100         |
