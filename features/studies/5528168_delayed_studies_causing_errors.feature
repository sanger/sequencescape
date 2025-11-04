@data_release @study
Feature: Delayed studies causing errors
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I have an "active" study called "Testing delayed studies"

  Scenario Outline: Study is delayed
    Given the study "Testing delayed studies" is delayed for <period> months because "It's not working"

    Given I allow redirects and am on the show page for study "Testing delayed studies"
    When I follow "Study details"
    Then I should see "<period> months"

    Examples:
      |period|
      |3     |
      |6     |
      |9     |
      |12    |
