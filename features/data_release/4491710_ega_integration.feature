@sample @accession_number @accession-service
Feature: Generate accession nubmers for a sample
  Background:
    Given I am logged in as "user123"

  Scenario: I am not the owner of a sample
    Given a study named "Study 4491710" exists
    Given study "Study 4491710" has a registered sample "Sample4491710"
    And an accession number is required for study "Study 4491710"
    Given I am on the show page for sample "Sample4491710"
    Then I should not see "Generate Accession Number"

  Scenario: The sample has no study
    Given a sample named "Sample4491710" exists
    Given I am the owner of sample "Sample4491710"
    Given I am on the show page for sample "Sample4491710"
    Given an accessioning webservice exists which returns a sample accession number "EGAN00001000234"
    When I follow "Generate Accession Number"
    Then I should not see "Accession number generated: EGAN00001000234"

  Scenario: The sample doesn't have the required properties filled in
    Given a study named "Study 4491710" exists
    And the study "Study 4491710" is a "Whole Genome Sequencing" study
    And the title of study "Study 4491710" is "Checking sample validation"
    And the description of study "Study 4491710" is "The study is valid, the sample is not"
    And the abstract of study "Study 4491710" is "Good study, bad sample"

    Given the study "Study 4491710" is a "genomic sequencing" study for data release
    And the study "Study 4491710" has an open data release strategy
    And the study "Study 4491710" data release timing is standard

    Given study "Study 4491710" has a registered sample "Sample4491710"
    And an accession number is required for study "Study 4491710"

    Given I am the owner of sample "Sample4491710"

    Given I am on the show page for sample "Sample4491710"
    Given an accessioning webservice exists which returns a sample accession number "EGAN00001000234"
    When I follow "Generate Accession Number"
    Then I should not see "Accession number generated: EGAN00001000234"

  Scenario: Study doesn't have any of the required properties filled in
    Given a study named "Study 4491710" exists
    And the abstract of study "Study 4491710" is ""
    Given study "Study 4491710" has a registered sample "Sample4491710"
    And an accession number is required for study "Study 4491710"

    Given I am the owner of sample "Sample4491710"
    And the sample "Sample4491710" has the Taxon ID "99999"
    And the sample "Sample4491710" has the common name "Human"

    Given I am on the show page for sample "Sample4491710"
    Given an accessioning webservice exists which returns a sample accession number "EGAN00001000234"
    When I follow "Generate Accession Number"
    Then I should not see "Accession number generated: EGAN00001000234"


  Scenario Outline: Study doesn't have some of the required data release properties filled in
    Given a study named "Study 4491710" exists
    And the study "Study 4491710" is a "<type>" study
    And the title of study "Study 4491710" is "<title>"
    And the description of study "Study 4491710" is "Description of study"
    And the abstract of study "Study 4491710" is "<study_abstract>"

    Given the study "Study 4491710" is a "genomic sequencing" study for data release
    And the study "Study 4491710" has a <Strategy> data release strategy
    And the study "Study 4491710" data release timing is standard

    Given study "Study 4491710" has a registered sample "Sample4491710"
    And an accession number is required for study "Study 4491710"

    Given I am the owner of sample "Sample4491710"
    And the sample "Sample4491710" has the Taxon ID "99999"
    And the sample "Sample4491710" has the common name "Human"

    Given I am on the show page for sample "Sample4491710"
    Given an accessioning webservice exists which returns a sample accession number "EGAN00001000234"
    When I follow "Generate Accession Number"
    Then I should not see "Accession number generated: EGAN00001000234"
    # NOTE: strategy, timing and description cannot be empty by definition
    Examples:
      | Strategy | title    | type                    | study_abstract |
      | open     | My title | Not specified           | abstract       |
      | managed  | My title | Not specified           | abstract       |

  Scenario Outline: Sample is released to EBI
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
    And the study "Study 4491710" contains samples commercially available
    And study "Study 4491710" has an accession number

    Given study "Study 4491710" has a registered sample "Sample4491710"
    And an accession number is required for study "Study 4491710"

    Given I am the owner of sample "Sample4491710"
    And the sample "Sample4491710" has the Taxon ID "99999"
    And the sample "Sample4491710" has the common name "Human"
    And the sample "Sample4491710" has the phenotype "Healthy"
    And the sample "Sample4491710" has the gender "Female"
    And the sample "Sample4491710" has the donor id "D0N0R"

    Given I am on the show page for sample "Sample4491710"
    Given an accessioning webservice exists which returns a sample accession number "<accession_number>"
    When I follow "Generate Accession Number"
    Then I should see "Accession number generated: <accession_number>"

    Examples:
      | data_release_strategy | accession_number |
      | open                  | EGAN00001000234  |
      | managed               | EGAN00001000234  |
