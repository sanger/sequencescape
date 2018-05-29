@pipeline
Feature: Pipeline shows status of requests in pipeline
    # I want to see red flag to show priority requests from the previous lab
    # And I want to see no entry sign for priority requests from the previous lab which have had a lane failure and a green tick if all are passed
    # Because these would need to be re-run before I can action them.

  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have administrative role
    And I have lab manager role
    And I have an "active" study called "Priority Study"
    And I have a control called "PhiX" for "Cluster formation SE"
    And I have a batch in "Illumina-C Library preparation"
    And I have a batch in "Illumina-C Library preparation"
    And I have a request for "Illumina-C Library preparation"

    And study "Priority Study" has asset and assetgroup
    And study "Priority Study" has a registered sample "SampleToFail"
    And study "Priority Study" has a registered sample "SampleToPass"
    And sample "SampleToPass" is in a sample tube named "TubeToPass"
    And sample "SampleToFail" is in a sample tube named "TubeToFail"
    And study "Priority Study" has made the following "Library creation" requests:
    | state   | count| asset      | sample      |
    | started | 1    | TubeToPass | SampletoPass|
    | failed  | 1    | TubeToFail | SampleToFail|

  Scenario: I can see the sample in the asset
    Given I am on the show page for sample "SampleToFail"
    Then I should see "Priority Study"
    And I should see "SampleToFail"

    Given I am on the show page for sample "SampleToPass"
    Then I should see "Priority Study"
    And I should see "SampleToPass"

  Scenario:  I see the failed Illumina-C Library preparation request for the study
    Given I am visiting study "Priority Study" homepage
    Then the page should contain the following
      | request type        | requested | pending | started | passed | failed | cancelled |
      | Library preparation | 2         | 0       | 2       | 1      | 1      | 0         |
