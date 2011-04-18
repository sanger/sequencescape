@study @ega @related_studies @accession_number @accession-service
Feature: A private study with a related public study should use it for accession
  Background:
    Given I am an "administrator" user logged in as "me"
    Given a study named "private study" exists
    And the study "private study" has a managed data release strategy
    And an accession number is required for study "private study"
    And the title of study "private study" is "Testing accession numbers"
    And the description of study "private study" is "To find out if something is broken"
    And the abstract of study "private study" is "Ok, not ok?"
    And the study "private study" is a "Whole Genome Sequencing" study

    Given an accessioning webservice exists which returns a study accession number "EGS00012345"
    Given a study named "public study" exists
    And the study "public study" has a open data release strategy
    Given the study "public study" is "sra public study" of study "private study"

  Scenario: getting the accession for the private study should link to the public study accession number
    Given the study "public study" has the accession number "EGAN00001000123"
    When I get the XML accession for the study "private study"
    Then the text of the XML element "//RELATED_STUDY/RELATED_LINK/DB" should be "ENA-STUDY"
    And the text of the XML element "//RELATED_STUDY/RELATED_LINK/ID" should be "EGAN00001000123"
    When I generate an accession number for study "private study"
    Then I should not see "accession number needed for related study"
    Then I should see "Accession number generated: EGS00012345"

  Scenario: getting the accession for the private study should fail if the public study doesn't have an accession number
    When I generate an accession number for study "private study"
    Then I should not see "Accession number generated: EGS00012345"
    Then I should see "Accession number needed for related study public study"



