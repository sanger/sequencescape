@pipeline @batch @javascript
Feature:
  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have administrative role

  Scenario Outline: Make training batch
    Given I have a batch in "<pipeline_type>"
    Given I have a request for "<pipeline_type>"
    When I go to the homepage
    Then I should be logged in as "user"

    When I follow "Pipelines"
    When I follow "<pipeline_type>"
    Then I should see "Read length"
    Then I should see "Library type"

    Scenarios: Non-HiSeq read lengths
      | pipeline_type                                  |
      | Cluster formation SE                           |
      | Cluster formation PE                           |
      | Cluster formation PE (no controls)             |
      | Cluster formation SE (no controls)             |
      | Cluster formation SE (spiked in controls)      |
      | Cluster formation PE (spiked in controls)      |

    Scenarios: HiSeq read lengths
      | pipeline_type                                  |
      | HiSeq Cluster formation PE (no controls)       |
      | Cluster formation SE HiSeq                     |
      | Cluster formation SE HiSeq (no controls)       |
