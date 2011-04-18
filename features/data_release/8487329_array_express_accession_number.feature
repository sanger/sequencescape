@study @accession_number @array_express @accession-service
Feature: Array express accession number should be parsed and saved
  Background:
    Given I am an "administrator" user logged in as "me"
  Scenario: The array express accession number is saved to the study
    Given a study named "study" exists for array express
    Given an accessioning service exists which returns an array express accession number "E-ERA-16"
    When I generate an array express accession number for study "study"
    And I am on the details page for study "study"
    Then I should see "E-ERA-16"



