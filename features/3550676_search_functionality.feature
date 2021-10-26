@search
Feature: Searching sequencescape
  Background:
    Given I am logged in as "user"
    And I am on the search page

    Given a project named "This Rabbit" exists
    And a study named "This Study" exists
    And a sample named "SampleForThis" exists
    And sample "SampleForThis" is in a sample tube named "This Asset"

  Scenario Outline: Searching
    When I fill in "Search for" with "<search>"
    And I press "Go"
    Then I should be on the search page
    And I should see "1 <type>"
    And I should see "<result>"

    Examples:
      |  search |   type  |   result       |
      | Rabbit  | project | This Rabbit    |
      | Study   | study   | This Study     |
      | Sample  | sample  | SampleForThis  |
      | Asset   | labware | This Asset     |

  Scenario: No matching results
    When I fill in "Search for" with "No way this will ever match anything!"
    And I press "Go"
    Then I should be on the search page
    And I should see "No results"

  Scenario: Searching for everything
    When I fill in "Search for" with "This"
    And I press "Go"
    Then I should be on the search page
    And the search results I should see are:
      | section |   result      |
      | project | This Rabbit  |
      | study   | This Study    |
      | sample  | SampleForThis |
      | labware | This Asset    |
