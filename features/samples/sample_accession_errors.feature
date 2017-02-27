@accession_number @accession-service
Feature: object with an accession should be modifiable
  Background:
    Given I am an "administrator" user logged in as "me"
    Given a study named "Study accession test" exists
    Given the study "Study accession test" is a "genomic sequencing" study for data release
      And the study "Study accession test" has a managed data release strategy
      And the study "Study accession test" data release timing is standard
      And the study "Study accession test" has samples contaminated with human DNA
      And the study "Study accession test" contains human DNA
      And study "Study accession test" has an accession number

  Scenario: Accessioning errors should be informative
    Given study "Study accession test" has a registered sample "sampletest"
      And I am on the show page for sample "sampletest"
     When I follow "Generate Accession Number"
     Then I should see "Please fill in the required fields:"
     And I should see "gender is required"
     And I should see "phenotype is required"
