@study @study_required
Feature: Creating studies
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario: Managed studies should warn missing user groups
    When I have a managed study without a data release group called "Bad study"
    And I am visiting study "Bad study" homepage
    When I follow "Manage"
    And I should see "Data access group"
    Then I should see "No user group specified for a managed study."
    When I fill in "Data access group" with "group1"
    And I press "Update"
    Then should see "Manage study: Bad study"
    And I should see "Your study has been updated"
    And I should not see "No user group specified for a managed study."

  Scenario: Unmanaged studies don't warn on missing user groups
    When I have a open study without a data release group called "Good study"
    And I am visiting study "Good study" homepage
    When I follow "Manage"
    Then I should not see "No user group specified for a managed study."




