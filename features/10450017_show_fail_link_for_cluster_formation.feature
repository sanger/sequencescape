@batch
Feature: Show link "Fail" only for cluster formation pipeline

Background:
  Given I am logged in as "user"
  And I am on the homepage

  Scenario Outline: Cluster formation should see the link
    Given I have a "released" batch in "<pipeline_type>"
    When I follow "Batches"
    When I follow "<pipeline_type>"
    And I am on the last batch show page
    Then I should see "This batch belongs to pipeline: <pipeline_type>"
    And I should see "Fail batch or items"

  Examples:
    | pipeline_type                                   |
    | Cluster formation SE                            |
    | Cluster formation PE                            |
    | Cluster formation SE HiSeq (spiked in controls) |
    | Cluster formation SE HiSeq (no controls)        |
    | Cluster formation SE (no controls)              |
    | Cluster formation SE (spiked in controls)       |
    | Cluster formation SE HiSeq                      |
    | Cluster formation PE (spiked in controls)       |
    | HiSeq Cluster formation PE (no controls)        |
    | HiSeq Cluster formation PE (spiked in controls) |
    | Cluster formation PE (no controls)              |
