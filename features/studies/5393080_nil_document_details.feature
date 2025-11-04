@javascript @study @document
Feature: Managing a study or project should not attach nil documents
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have an active study called "Study testing nil documents"
    Given I allow redirects and am on the show page for study "Study testing nil documents"
    And I follow "Manage"

  Scenario: Managing a study without attaching a file
    When I press "Update"
    Then I should see "Your study has been updated"
    And I should not see "Listing 1 document"
    And I should not find any nil documents

  Scenario: Managing a study and attaching a file
    When I attach the relative file "test/data/blah.fasta" to "Attach HMDMC approval"
    And I press "Update"
    Then I should see "Your study has been updated"
    And I should see "Listing 1 document"
    And I should see "blah.fasta"
    And I should not find any nil documents
