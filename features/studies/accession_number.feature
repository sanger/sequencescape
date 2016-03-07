# rake features FEATURE=features/plain/studies/accession_number.feature
@study @accession_number @accession-service
Feature: Studies should be able to generate accession numbers
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given a study named "Study for accession number testing" exists
    And the title of study "Study for accession number testing" is "Testing accession numbers"
    And the description of study "Study for accession number testing" is "To find out if something is broken"
    And the abstract of study "Study for accession number testing" is "Ok, not ok?"
    And the study "Study for accession number testing" is a "Whole Genome Sequencing" study

    Given I am on the workflow page for study "Study for accession number testing"

  Scenario: The study does not have an accession number but doesn't need one anyway
    When I follow "Generate Accession Number"
    Then I should be on the workflow page for study "Study for accession number testing"
    And I should see "An accession number is not required for this study"

  Scenario: The study already has an accession number
    Given an accessioning webservice exists which returns a study accession number "EGAN00001000234"
    Given an accession number is required for study "Study for accession number testing"
    And the study "Study for accession number testing" has the accession number "EGAN00001000235"
    When I follow "Generate Accession Number"
    Then I should see "Accession number generated: EGAN00001000234"

  Scenario Outline: The study has data missing from the required fields
    Given an accession number is required for study "Study for accession number testing"
    Given the <attribute> of study "Study for accession number testing" is ""

    When I follow "Generate Accession Number"
    And I should see "Please fill in the required fields"

    Examples:
      | attribute   |
      | title       |
      | abstract    |

  Scenario: The study gets a valid accession number
    Given an accessioning webservice exists which returns a study accession number "EGAN00001000234"

    Given an accession number is required for study "Study for accession number testing"

    When I follow "Generate Accession Number"
    #    Then I should be on the workflow page for study "Study for accession number testing"
    And I should see "Accession number generated: EGAN00001000234"
    Given I am on the workflow page for study "Study for accession number testing"
    When I follow "Study details"
    Then I should see "EGAN00001000234"

  Scenario: The accession number service gives an error
    Given an accessioning webservice exists that errors with "We are experiencing problems, sorry"

    Given an accession number is required for study "Study for accession number testing"

    When I follow "Generate Accession Number"
    Then I should see "We are experiencing problems, sorry"

  Scenario: There are problems contacting the accession number service
    Given an accessioning webservice is unavailable

    Given an accession number is required for study "Study for accession number testing"

    When I follow "Generate Accession Number"
    Then I should see "EBI may be down or invalid data submitted"

