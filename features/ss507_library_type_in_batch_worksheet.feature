@spiked
Feature: Creating Spiked phiX
  Background:
    Given I am an "administrator" user logged in as "me"


  Scenario: The cluster formation team member create a batch that will use spiked in controls.
    Given I have a batch with 8 requests for the "Cluster formation PE (spiked in controls)" pipeline
    When I on batch page
    And I follow "Print worksheet"
    Then I should see "Library Types"
    And I should see "Standard"
