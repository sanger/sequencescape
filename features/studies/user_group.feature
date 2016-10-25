@study @study_required
Feature: Creating studies
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario: Unmanaged studies don't warn on missing user groups
    When I have a open study without a data release group called "Good study"
    And I am visiting study "Good study" homepage
    When I follow "Manage"
    Then I should not see "No user group specified for a managed study."




