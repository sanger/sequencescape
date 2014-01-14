@submission @asset @request @javascript
Feature: Requesting additional sequencing for cross study requests
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have a project called "Project A"
    And I have a project called "Project B"

    Given I have an "active" study called "Study A"
    And I have an "active" study called "Study B"

  Scenario: Submission succeeds

    Given the study "Study A" has a library tube called "library tube 1"
    And the study "Study B" has a library tube called "library tube 2"

    And the library tube "library tube 1" has aliquots with tag 1 under project "Project A"
    And the library tube "library tube 2" has aliquots with tag 2 under project "Project B"

    And I have a multiplexed library tube called "multiplex 1"
    And the multiplexed library tube "multiplex 1" contains "library tube 1"
    And the multiplexed library tube "multiplex 1" contains "library tube 2"

    Given I am on the show page for asset "multiplex 1"
    When I follow "Request additional sequencing"
    And I select "Illumina-C HiSeq Paired end sequencing" from "Request type"
    And the checkbox labeled "Cross Study Request" should be checked
    And the checkbox labeled "Cross Project Request" should be checked
    And I fill in "Fragment size required (from)" with "100" for the "Illumina-C HiSeq Paired end sequencing" request type
    And I fill in "Fragment size required (to)" with "200" for the "Illumina-C HiSeq Paired end sequencing" request type
    And I select "100" from "Read length" for the "Illumina-C HiSeq Paired end sequencing" request type
    And I press "Create"
    Then I should see "Created request"

    # Ensure that the submission can be processed validly
    Given all pending delayed jobs are processed
    Then the multiplexed library tube "multiplex 1" should have 1 "Illumina-C HiSeq Paired end sequencing" requests
    And the "Illumina-C HiSeq Paired end sequencing" requests on "multiplex 1" should have no study or project
    And the last submission should be called "Study A|Study B"

  Scenario: Submission succeeds

    Given the study "Study A" has a library tube called "library tube 1"
    And the study "Study A" has a library tube called "library tube 2"

    And the library tube "library tube 1" has aliquots with tag 1 under project "Project A"
    And the library tube "library tube 2" has aliquots with tag 2 under project "Project A"

    And I have a multiplexed library tube called "multiplex 1"
    And the multiplexed library tube "multiplex 1" contains "library tube 1"
    And the multiplexed library tube "multiplex 1" contains "library tube 2"

    Given I am on the show page for asset "multiplex 1"
    When I follow "Request additional sequencing"
    Then I should not see "Cross Study Request"
    And I should not see "Cross Project Request"

