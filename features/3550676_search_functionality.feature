@search
Feature: Searching sequencescape
  Background:
    Given I am logged in as "user"
    And I am on the search page

    Given a project named "My Project" exists
    And a study named "My Study" exists
    And a sample named "SampleForMy" exists
    And sample "SampleForMy" is in a sample tube named "My Asset"

  Scenario Outline: Searching
    When I fill in "Search for" with "<search>"
    And I press "Go"
    Then I should be on the search page
    And I should see "1 <type>"
    And I should see "<result>"

    Examples:
      |  search |   type  |   result     |
      | Project | project | My Project   |
      | Study   | study   | My Study     |
      | Sample  | sample  | SampleForMy  |
      | Asset   | asset   | My Asset     |

  @wip
  Scenario: Searching for a request

  Scenario: No matching results
    When I fill in "Search for" with "No way this will ever match anything!"
    And I press "Go"
    Then I should be on the search page
    And I should see "No results"

  Scenario: Searching for everything
    When I fill in "Search for" with "My"
    And I press "Go"
    Then I should be on the search page
    And the search results I should see are:
      | section |   result    |
      | project | My Project  |
      | study   | My Study    |
      | sample  | SampleForMy |
      | asset   | My Asset    |
