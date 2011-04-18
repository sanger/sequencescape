@batch
Feature: Change the side links in a batch depending on the pipeline

  Background: 
    Given I am logged in as "user"
    And I have lab manager role 

  Scenario Outline: Menu displayed 
    Given I have a batch in "<pipeline>"
      And I am on the last batch show page
    Then I should see "Edit"
      And I <see_or_not_see> "Print stock labels"
      And I <see_or_not_see_2> "Create stock tubes"
      And I <see_or_not_see_2> "Vol' & Conc'"

    Examples:
      | pipeline                      |  see_or_not_see | see_or_not_see_2 |
      | Cluster formation PE          |  should not see | should not see   |
      | Cluster formation SE          |  should not see | should not see   |
      | Library preparation           |  should see     | should see       |
      | Genotyping                    |  should not see | should see       |
      | MX Library Preparation [NEW]  |  should not see | should see       |
      | Cherrypick                    |  should not see | should see       |
      | DNA QC                        |  should not see | should see       |
