@study @accession_number @dac @policy @accession-service
Feature: Dac and Policy should be able to generate accession numbers
  Background:
    Given I am an "administrator" user logged in as "me"

  Scenario Outline: A managed study has a valid  <object> set but no accession number for it
    Given a study named "managed study" exists
    Given the study "managed study" has a managed data release strategy
    Given the study "managed study" has a valid <object>
    Given an accessioning webservice exists which returns a <object> accession number "EGAP00001000234"
    When I generate a <object> accession number for study "managed study"
    And I am on the workflow page for study "managed study"
    And I follow "Study details"
    Then I should see "EGAP00001000234"
  Examples:
    | object |
    | policy |
    | dac  |

  Scenario Outline: A open study has a valid  <object> set but no accession number for it. Should fail.
    Given a study named "open study" exists
    Given the study "open study" has a open data release strategy
    Given the study "open study" has a valid <object>
    Given an accessioning webservice exists which returns a <object> accession number "EGAP00001000234"
    When I generate a <object> accession number for study "open study"
    Then I should see "No accession number was generated"
  Examples:
    | object |
    | policy |
    | dac  |

  Scenario: A managed study has an invalid DAC
    Given a study named "managed study" exists
    Given the study "managed study" has a managed data release strategy
    Given an accessioning webservice exists which returns a dac accession number "EGAP00001000234"
    When I generate a dac accession number for study "managed study"
    Then I should see "Data Access Contacts Empty"
    And I am on the workflow page for study "managed study"
    And I follow "Study details"
    Then I should not see "EGAP00001000234"
