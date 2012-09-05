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
    And I have an associated workflow "Next-gen sequencing"
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

 # to be implemented!
 # And study "Priority Study" has made the following "Cluster formation SE" requests:
 #   | state   | count| asset      | sample      |
 #   | pending | 1    | TubeToPass | SampletoPass|
 #   | pending | 1    | TubeToFail | SampleToFail|

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

  @wip
  Scenario: I see the failure in Library Preparation from the Cluster formation page
    Given I am on the show page for pipeline "Cluster formation SE"
    Then I should see "Cluster"

  Scenario: I make a training batch for SE pipeline
    Given I am on the show page for pipeline "Cluster formation SE"
    When I follow "Make training batch"
    When I press "Create batch"
    Then I should see "Edit batch"

    When I follow "Start batch"
    Then I should see "View all batches"

    When I press "Next step"
    Then I should see "Source barcode"

    When I press "Next step"
    Then I should see "Quality control"

    When I press "Next step"
    Then I should see "Lin/block/hyb/load"

    When I press "Next step"
    Then I should see "Specify Dilution Volume"

    When I press "Release this batch"
    Then I should see "Batch released"
