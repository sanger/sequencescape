@batch
Feature: If a batch is released, the section Action/Task shouldnt show 

  Background: 
    Given I am logged in as "user"

  Scenario Outline: The batch is released and the section Action isnt show
    Given I have a batch in "<pipeline>" with state released
    And I am on the last batch show page
    Then I should see "This batch belongs to pipeline: <pipeline>"
    And I should see "EVENTS"
    And I should not see "ACTIONS"
  Examples:
    | pipeline                      |
    | Cluster formation PE          |
    | MX Library Preparation [NEW]  |
    | Library preparation           |

  Scenario Outline: The batch is pending and the section Action is showed 
    Given I have a batch in "<pipeline>"
    And I am on the last batch show page
    Then I should see "This batch belongs to pipeline: <pipeline>"
    And I should see "EVENTS"
    And I should see "ACTIONS"

    Examples:
      | pipeline                      |
      | Cluster formation PE          |
      | MX Library Preparation [NEW]  |
      | Library preparation           |

    
