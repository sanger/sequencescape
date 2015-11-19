@accession_number @accession-service
Feature: object with an accession should be modifiable
  Background:
    Given I am an "administrator" user logged in as "me"

  @study
  Scenario: A study with already an accession number should add updated in the history
    Given a study named "study" exists for accession
    And the study "study" has the accession number "E-ERA-16"
    Given an accessioning webservice exists which returns a study accession number "E-ERA-16"
    When I update an accession number for study "study"

    When I am on the event history page for study "study"
    Then I should see "accession data has been updated by user me"

  Scenario: A sample without an accession number should not sent public name as alias but an uuid
    Given a sample named "sample" exists for accession
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    Given I am on the show page for sample "sample"
    And the UUID for the sample "sample" is "11111111-1111-1111-1111-1111111111"
    When I create an accession number for sample "sample"

    Then the XML root attribute "alias" sent to the accession service for sample "sample" should be "11111111-1111-1111-1111-1111111111"

  Scenario Outline: A sample should send a title element with sample public name falling back to sanger id if not present
    Given a sample named "sample" exists for accession
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    Given I am on the show page for sample "sample"
    And the metadata attribute "sample_public_name" of the sample "sample" is <sample_public_name>
    And the attribute "sanger_sample_id" of the sample "sample" is <sanger_sample_id>
    When I create an accession number for sample "sample"

    Then the XML identifier tag "TITLE" sent to the accession service for sample "sample" should be <title>

    Examples:
      | sample_public_name                | sanger_sample_id                       | title                                  |
      | "this is a public name of sample" | "this is a sanger_sample_id of sample" | "this is a public name of sample"      |
      | "this is a public name of sample" | "empty"                                | "this is a public name of sample"      |
      | "empty"                           | "this is a sanger_sample_id of sample" | "this is a sanger_sample_id of sample" |
      | "empty"                           | "empty"                                | not present                            |

  Scenario: A sample with already an accession number should add updated in the history
    Given a sample named "sample" exists for accession
    And the sample "sample" has the accession number "E-ERA-16"
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    When I am on the event history page for sample "sample"
    Then I should see "accession data has been updated by user me"

  Scenario: A sample with already an accession number should update itself using its accession number
    Given a sample named "sample" exists for accession
    And the sample "sample" has the accession number "E-ERA-16"
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    Then I should not have sent the attribute "alias" for the sample element to the accessioning service
      And I should have sent the attribute "accessor" for the sample element to the accessioning service
      And I should have received the attribute "accessor" for the sample element from the accessioning service

  Scenario: A sample without an accession number should update itself using its alias
    Given a sample named "sample" exists for accession
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I create an accession number for sample "sample"

    Then I should have sent the attribute "alias" for the sample element to the accessioning service
      And I should not have sent the attribute "accessor" for the sample element to the accessioning service
      And I should have received the attribute "accessor" for the sample element from the accessioning service

