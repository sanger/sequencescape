@sample @accession_number @accession-service
Feature: Generate Sample Accessions
  In order to automatically assign ega accession numbers to studies
  As a script run by cron
  I want find a list of samples which need accession numbers and get accessions for them


  Scenario Outline: When we have a Study with a Managed Data Strategy
      Given a user with an api key of "abc" exists

      Given a study named "Study 4491710" exists
      And the study "Study 4491710" is a "Whole Genome Sequencing" study
      And the title of study "Study 4491710" is "My title"
      And the description of study "Study 4491710" is "Description of study"
      And the abstract of study "Study 4491710" is "My abstract"
      And the faculty sponsor for study "Study 4491710" is "John Doe"

    Given the study "Study 4491710" is a "genomic sequencing" study for data release
      And the study "Study 4491710" has a <data_release_strategy> data release strategy
      And the study "Study 4491710" data release timing is standard
      And the study "Study 4491710" has samples contaminated with human DNA
      And the study "Study 4491710" contains human DNA

    Given study "Study 4491710" has a registered sample "Sample4491710"
      And an accession number is required for study "Study 4491710"
      And study "Study 4491710" has an accession number

    Given I am the owner of sample "Sample4491710"
      And the sample "Sample4491710" has the Taxon ID "99999"
      And the sample "Sample4491710" has the common name "Human"
      And the sample "Sample4491710" has the donor id "<donor_id>"
      And the sample "Sample4491710" has the gender "<gender>"
      And the sample "Sample4491710" has the phenotype "<phenotype>"
      And the sample "Sample4491710" should not have an accession number
      And the sample "Sample4491710" should <accession> an accesionable flag
      And an accessioning webservice exists which returns a sample accession number "<accession_number>"

    When I run the "generate_sample_accessions.rb" cron script
    Then sample "Sample4491710" should <accession> an accession number of "<accession_number>"


    Examples:
      | data_release_strategy | accession_number | gender | donor_id | phenotype | accession |
      | open                  | EGAN00001000234  |        |          |           | have      |
      | managed               | EGAN00001000234  | male   | D0N0R    | cancer    | have      |
      | managed               | EGAN00001000234  | male   |          | healthy   | not have  |
      | managed               | EGAN00001000234  | male   |          |           | not have  |


