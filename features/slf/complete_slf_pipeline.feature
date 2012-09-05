@slf @javascript @sequenom @barcode-service
Feature: I wish to create samples and push them all the way through QC in SLF
  Background:
    Given the Sanger sample IDs will be sequentially generated

    Given I am a "administrator" user logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given user "jack" exists with barcode "ID100I"
    Given a faculty sponsor called "Jack Sponsor" exists

    # NOTE: The first barcode is used for all of the child plates, except one, but the code still
    # seems to need the additional barcodes for some reason.  Can't quite work that one out at the
    # moment.
    Given the plate barcode webservice returns "1234567"
    And the plate barcode webservice returns "1000000..1000001"
    And the plate barcode webservice returns "99999"

    Given a plate template exists
    Given a robot exists
    Given a supplier called "Test supplier name" exists

  @manifest
  Scenario: Push a plate all the way through SLF to genotyping
    Given I have a project called "Test project"
    And project "Test project" has enough quotas

    When I go to the homepage
    And I follow "Create study"
    When I fill in "Study name" with "Test study"
    And I fill in "Study description" with "writing cukes"
    And I fill in "ENA Study Accession Number" with "12345"
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I fill in "Study name abbreviation" with "CCC3"
    And I select "Yes" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "No" from "Does this study require the removal of X chromosome and autosome sequence?"
    And I select "open" from "What is the data release strategy for this study?"

    # NOTE[xxx]: This feels like a bit of a hack but I can't see a way to turn off enforce_accessioning
    # at this level of the UI.  Apparently no studies that come through the SLF pipeline will need accession
    # numbers and so it's trying to turn that check off.
    And I select "genotyping or cytogenetics" from "What sort of study is this?"
    When I press "Create"

    Given I am on the sample db homepage
    When I follow "Create manifest for plates"
    When I select "Test study" from "Study"
    And I select "default layout" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz" from "Barcode printer"
    And I fill in "Count" with "1"
    When I press "Create manifest and print labels"
    Given 3 pending delayed jobs are processed
    When I follow "View all manifests"
    When I follow "Manifest for Test study"
    Then study "Test study" should have 96 samples

    # Then I should fill in the spreadsheet offline and save as a csv
    # And I should upload the file
    Given sample information is updated from the manifest for study "Test study"

    Given the internal QC plates are created
    Given I have a "DNA QC - Cherrypick - Genotyping" submission for plate "1234567" with project "Test project" and study "Test study"

    Given I am on the gel QC page
    When I fill in "barcode" with "1234567"
    When I press "Update gel values"
    When I select from the following:
      | Well A1 | No Band |
      | Well B2 | Pass    |
      | Well C3 | Fail    |
      | Well D4 | Weak    |
      | Well E5 | Degraded|
    And I press "Update gel values"

    Given plate "1221234567841" has concentration and sequenom results

    When I follow "Reception"
    When I select "Plate" from "type_id"
    And I fill in "barcode_0" with "1221234567841"
    And I press "Submit"
    When I select "Sample logistics freezer" from "asset_location_id"
    And I press "Confirm"

    Given I am on the show page for pipeline "DNA QC"

    When I check "Select DN1234567T for batch"
    And I select "Create Batch" from "action_on_requests"
    And I press "Submit"
    When I follow "Start batch"
    Then I should see dna qc table:
     | Well | Gel              | Pico | Sequenom   | Gender | Concentration | Plate         |
     | A1   | Band Not Visible | Pass | 0/30 FFFF  | F      | 5.0           | Plate 1234567 |
     | B1   | OK               | Pass | 1/30 FFFF  | F      | 6.0           | Plate 1234567 |
     | C1   | OK               | Pass | 2/30 FFFF  | F      | 7.0           | Plate 1234567 |
     | D1   | OK               | Pass | 3/30 FFFF  | F      | 8.0           | Plate 1234567 |
     | E1   | OK               | Pass | 4/30 FFFF  | F      | 9.0           | Plate 1234567 |
     | F1   | OK               | Pass | 5/30 FFFF  | F      | 10.0          | Plate 1234567 |
     | G1   | OK               | Pass | 6/30 FFFF  | F      | 11.0          | Plate 1234567 |
     | H1   | OK               | Pass | 7/30 FFFF  | F      | 12.0          | Plate 1234567 |
     | A2   | OK               | Pass | 8/30 FFFF  | F      | 13.0          | Plate 1234567 |
     | B2   | OK               | Pass | 9/30 FFFF  | F      | 14.0          | Plate 1234567 |
     | C2   | OK               | Pass | 10/30 FFFF | F      | 15.0          | Plate 1234567 |
     | D2   | OK               | Pass | 11/30 FFFF | F      | 16.0          | Plate 1234567 |
     | E2   | OK               | Pass | 12/30 FFFF | F      | 17.0          | Plate 1234567 |
     | F2   | OK               | Pass | 13/30 FFFF | F      | 18.0          | Plate 1234567 |
     | G2   | OK               | Pass | 14/30 FFFF | F      | 19.0          | Plate 1234567 |
     | H2   | OK               | Pass | 15/30 FFFF | F      | 20.0          | Plate 1234567 |
     | A3   | OK               | Pass | 16/30 FFFF | F      | 21.0          | Plate 1234567 |
     | B3   | OK               | Pass | 17/30 FFFF | F      | 22.0          | Plate 1234567 |
     | C3   | Fail             | Pass | 18/30 FFFF | F      | 23.0          | Plate 1234567 |
     | D3   | OK               | Pass | 19/30 FFFF | F      | 24.0          | Plate 1234567 |
     | E3   | OK               | Pass | 20/30 FFFF | F      | 25.0          | Plate 1234567 |
     | F3   | OK               | Pass | 21/30 FFFF | F      | 26.0          | Plate 1234567 |
     | G3   | OK               | Pass | 22/30 FFFF | F      | 27.0          | Plate 1234567 |
     | H3   | OK               | Pass | 23/30 FFFF | F      | 28.0          | Plate 1234567 |
     | A4   | OK               | Pass | 24/30 FFFF | F      | 29.0          | Plate 1234567 |
     | B4   | OK               | Pass | 25/30 FFFF | F      | 30.0          | Plate 1234567 |
     | C4   | OK               | Pass | 26/30 FFFF | F      | 31.0          | Plate 1234567 |
     | D4   | Weak             | Pass | 27/30 FFFF | F      | 32.0          | Plate 1234567 |
     | E4   | OK               | Pass | 28/30 FFFF | F      | 33.0          | Plate 1234567 |
     | F4   | OK               | Pass | 29/30 FFFF | F      | 34.0          | Plate 1234567 |
     | G4   | OK               | Pass | 0/30 FFFF  | F      | 35.0          | Plate 1234567 |
     | H4   | OK               | Pass | 1/30 FFFF  | F      | 36.0          | Plate 1234567 |
     | A5   | OK               | Pass | 2/30 FFFF  | F      | 37.0          | Plate 1234567 |
     | B5   | OK               | Pass | 3/30 FFFF  | F      | 38.0          | Plate 1234567 |
     | C5   | OK               | Pass | 4/30 FFFF  | F      | 39.0          | Plate 1234567 |
     | D5   | OK               | Pass | 5/30 FFFF  | F      | 40.0          | Plate 1234567 |
     | E5   | Degraded         | Pass | 6/30 FFFF  | F      | 41.0          | Plate 1234567 |
     | F5   | OK               | Pass | 7/30 FFFF  | F      | 42.0          | Plate 1234567 |
     | G5   | OK               | Pass | 8/30 FFFF  | F      | 43.0          | Plate 1234567 |
     | H5   | OK               | Pass | 9/30 FFFF  | F      | 44.0          | Plate 1234567 |
     | A6   | OK               | Pass | 10/30 FFFF | F      | 45.0          | Plate 1234567 |
     | B6   | OK               | Pass | 11/30 FFFF | F      | 46.0          | Plate 1234567 |
     | C6   | OK               | Pass | 12/30 FFFF | F      | 47.0          | Plate 1234567 |
     | D6   | OK               | Pass | 13/30 FFFF | F      | 48.0          | Plate 1234567 |
     | E6   | OK               | Pass | 14/30 FFFF | F      | 49.0          | Plate 1234567 |
     | F6   | OK               | Pass | 15/30 FFFF | F      | 50.0          | Plate 1234567 |
     | G6   | OK               | Pass | 16/30 FFFF | F      | 51.0          | Plate 1234567 |
     | H6   | OK               | Pass | 17/30 FFFF | F      | 52.0          | Plate 1234567 |
     | A7   | OK               | Pass | 18/30 FFFF | F      | 53.0          | Plate 1234567 |
     | B7   | OK               | Pass | 19/30 FFFF | F      | 54.0          | Plate 1234567 |
     | C7   | OK               | Pass | 20/30 FFFF | F      | 5.0           | Plate 1234567 |
     | D7   | OK               | Pass | 21/30 FFFF | F      | 6.0           | Plate 1234567 |
     | E7   | OK               | Pass | 22/30 FFFF | F      | 7.0           | Plate 1234567 |
     | F7   | OK               | Pass | 23/30 FFFF | F      | 8.0           | Plate 1234567 |
     | G7   | OK               | Pass | 24/30 FFFF | F      | 9.0           | Plate 1234567 |
     | H7   | OK               | Pass | 25/30 FFFF | F      | 10.0          | Plate 1234567 |
     | A8   | OK               | Pass | 26/30 FFFF | F      | 11.0          | Plate 1234567 |
     | B8   | OK               | Pass | 27/30 FFFF | F      | 12.0          | Plate 1234567 |
     | C8   | OK               | Pass | 28/30 FFFF | F      | 13.0          | Plate 1234567 |
     | D8   | OK               | Pass | 29/30 FFFF | F      | 14.0          | Plate 1234567 |
     | E8   | OK               | Pass | 0/30 FFFF  | F      | 15.0          | Plate 1234567 |
     | F8   | OK               | Pass | 1/30 FFFF  | F      | 16.0          | Plate 1234567 |
     | G8   | OK               | Pass | 2/30 FFFF  | F      | 17.0          | Plate 1234567 |
     | H8   | OK               | Pass | 3/30 FFFF  | F      | 18.0          | Plate 1234567 |
     | A9   | OK               | Pass | 4/30 FFFF  | F      | 19.0          | Plate 1234567 |
     | B9   | OK               | Pass | 5/30 FFFF  | F      | 20.0          | Plate 1234567 |
     | C9   | OK               | Pass | 6/30 FFFF  | F      | 21.0          | Plate 1234567 |
     | D9   | OK               | Pass | 7/30 FFFF  | F      | 22.0          | Plate 1234567 |
     | E9   | OK               | Pass | 8/30 FFFF  | F      | 23.0          | Plate 1234567 |
     | F9   | OK               | Pass | 9/30 FFFF  | F      | 24.0          | Plate 1234567 |
     | G9   | OK               | Pass | 10/30 FFFF | F      | 25.0          | Plate 1234567 |
     | H9   | OK               | Pass | 11/30 FFFF | F      | 26.0          | Plate 1234567 |
     | A10  | OK               | Pass | 12/30 FFFF | F      | 27.0          | Plate 1234567 |
     | B10  | OK               | Pass | 13/30 FFFF | F      | 28.0          | Plate 1234567 |
     | C10  | OK               | Pass | 14/30 FFFF | F      | 29.0          | Plate 1234567 |
     | D10  | OK               | Pass | 15/30 FFFF | F      | 30.0          | Plate 1234567 |
     | E10  | OK               | Pass | 16/30 FFFF | F      | 31.0          | Plate 1234567 |
     | F10  | OK               | Pass | 17/30 FFFF | F      | 32.0          | Plate 1234567 |
     | G10  | OK               | Pass | 18/30 FFFF | F      | 33.0          | Plate 1234567 |
     | H10  | OK               | Pass | 19/30 FFFF | F      | 34.0          | Plate 1234567 |
     | A11  | OK               | Pass | 20/30 FFFF | F      | 35.0          | Plate 1234567 |
     | B11  | OK               | Pass | 21/30 FFFF | F      | 36.0          | Plate 1234567 |
     | C11  | OK               | Pass | 22/30 FFFF | F      | 37.0          | Plate 1234567 |
     | D11  | OK               | Pass | 23/30 FFFF | F      | 38.0          | Plate 1234567 |
     | E11  | OK               | Pass | 24/30 FFFF | F      | 39.0          | Plate 1234567 |
     | F11  | OK               | Pass | 25/30 FFFF | F      | 40.0          | Plate 1234567 |
     | G11  | OK               | Pass | 26/30 FFFF | F      | 41.0          | Plate 1234567 |
     | H11  | OK               | Pass | 27/30 FFFF | F      | 42.0          | Plate 1234567 |
     | A12  | OK               | Pass | 28/30 FFFF | F      | 43.0          | Plate 1234567 |
     | B12  | OK               | Pass | 29/30 FFFF | F      | 44.0          | Plate 1234567 |
     | C12  | OK               | Pass | 0/30 FFFF  | F      | 45.0          | Plate 1234567 |
     | D12  | OK               | Pass | 1/30 FFFF  | F      | 46.0          | Plate 1234567 |
     | E12  | OK               | Pass | 2/30 FFFF  | F      | 47.0          | Plate 1234567 |
     | F12  | OK               | Pass | 3/30 FFFF  | F      | 48.0          | Plate 1234567 |
     | G12  | OK               | Pass | 4/30 FFFF  | F      | 49.0          | Plate 1234567 |
     | H12  | OK               | Pass | 5/30 FFFF  | F      | 50.0          | Plate 1234567 |

    When I select "pass" for the first row of the plate
    And I press "Next step"
    # What page are we on?  Where in the process are we?
    # It would clarify things have a
    #   Then we should be on the <PAGE_NAME> call
    # and a corresponding entry in paths.rb

    # What does seeing "competed" mean?  What is competed?

    Given I am on the show page for pipeline "Cherrypick"
    When I check "Select DN1234567T for batch"
    And I select "Create Batch" from "action_on_requests"
    And I press "Submit"
    When I follow "Start batch"
    When I select "testtemplate" from "Plate Template"
    And I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    When I press "Next step"
    When I press "Next step"

    When I select "Infinium 670k" from "Plate Purpose"
    And I press "Next step"
    When I select "Genotyping freezer" from "Location"
    And I press "Next step"
    When I press "Release this batch"
    When I follow "Print plate labels"
    When I press "Print labels"
    Then I should see "Your labels have been printed"

    Given I am on the show page for pipeline "Genotyping"

    When I check "Select DN99999F for batch"
    And I select "Create Batch" from "action_on_requests"
    And I press "Submit"
    When I follow "Start batch"

    When I fill in "Infinium barcode for plate 99999" with "WG1234567"
    And I press "Next step"
    When I press "Next step"
    Then the manifest for study "Test study" with plate "99999" should be:
    | Row | Institute Plate Label | Well | Is Control | Institute Sample Label | Species      | Sex    | Volume (ul) | Conc (ng/ul) | Extraction Method | Mass of DNA used in WGA | Tissue Source |
    | 1   | WG1234567         | A01  | 0          | 99999_A01_CCC31        | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 2   | WG1234567         | B01  | 0          | 99999_B01_CCC39        | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 3   | WG1234567         | C01  | 0          | 99999_C01_CCC317       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 4   | WG1234567         | D01  | 0          | 99999_D01_CCC325       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 5   | WG1234567         | E01  | 0          | 99999_E01_CCC333       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 6   | WG1234567         | F01  | 0          | 99999_F01_CCC341       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 7   | WG1234567         | G01  | 0          | 99999_G01_CCC349       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 8   | WG1234567         | H01  | 0          | 99999_H01_CCC357       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 9   | WG1234567         | A02  | 0          | 99999_A02_CCC365       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 10  | WG1234567         | B02  | 0          | 99999_B02_CCC373       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 11  | WG1234567         | C02  | 0          | 99999_C02_CCC381       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    | 12  | WG1234567         | D02  | 0          | 99999_D02_CCC389       | Homo sapiens | F | 13          | 50           | -                 | 0                       | -             |
    When I press "Release this batch"

    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
    | Study      | Supplier           | Plate   | Supplier Volume | Supplier Gender | Concentration | Sequenome Count | Sequenome Gender | Pico | Gel              | Qc Status | DNA Source | Sanger Sample Name | Supplier Sample Name | Well | Genotyping Chip | Genotyping Infinium Barcode | Genotyping Well | Genotyping Barcode |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 5.0           | 0/30            | FFFF             | Pass | Band Not Visible | passed    | Blood      | CCC31              | CCC31                | A1   | Infinium 670k   | WG1234567               | A1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 6.0           | 1/30            | FFFF             | Pass | OK               | started   | Blood      | CCC32              | CCC32                | B1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 7.0           | 2/30            | FFFF             | Pass | OK               | started   | Blood      | CCC33              | CCC33                | C1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 8.0           | 3/30            | FFFF             | Pass | OK               | started   | Blood      | CCC34              | CCC34                | D1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 9.0           | 4/30            | FFFF             | Pass | OK               | started   | Blood      | CCC35              | CCC35                | E1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 10.0          | 5/30            | FFFF             | Pass | OK               | started   | Blood      | CCC36              | CCC36                | F1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 11.0          | 6/30            | FFFF             | Pass | OK               | started   | Blood      | CCC37              | CCC37                | G1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 12.0          | 7/30            | FFFF             | Pass | OK               | started   | Blood      | CCC38              | CCC38                | H1   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 13.0          | 8/30            | FFFF             | Pass | OK               | passed    | Blood      | CCC39              | CCC39                | A2   | Infinium 670k   | WG1234567               | B1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 14.0          | 9/30            | FFFF             | Pass | OK               | started   | Blood      | CCC310             | CCC310               | B2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 15.0          | 10/30           | FFFF             | Pass | OK               | started   | Blood      | CCC311             | CCC311               | C2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 16.0          | 11/30           | FFFF             | Pass | OK               | started   | Blood      | CCC312             | CCC312               | D2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 17.0          | 12/30           | FFFF             | Pass | OK               | started   | Blood      | CCC313             | CCC313               | E2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 18.0          | 13/30           | FFFF             | Pass | OK               | started   | Blood      | CCC314             | CCC314               | F2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 19.0          | 14/30           | FFFF             | Pass | OK               | started   | Blood      | CCC315             | CCC315               | G2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 20.0          | 15/30           | FFFF             | Pass | OK               | started   | Blood      | CCC316             | CCC316               | H2   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 21.0          | 16/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC317             | CCC317               | A3   | Infinium 670k   | WG1234567               | C1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 22.0          | 17/30           | FFFF             | Pass | OK               | started   | Blood      | CCC318             | CCC318               | B3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 23.0          | 18/30           | FFFF             | Pass | Fail             | failed    | Blood      | CCC319             | CCC319               | C3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 24.0          | 19/30           | FFFF             | Pass | OK               | started   | Blood      | CCC320             | CCC320               | D3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 25.0          | 20/30           | FFFF             | Pass | OK               | started   | Blood      | CCC321             | CCC321               | E3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 26.0          | 21/30           | FFFF             | Pass | OK               | started   | Blood      | CCC322             | CCC322               | F3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 27.0          | 22/30           | FFFF             | Pass | OK               | started   | Blood      | CCC323             | CCC323               | G3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 28.0          | 23/30           | FFFF             | Pass | OK               | started   | Blood      | CCC324             | CCC324               | H3   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 29.0          | 24/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC325             | CCC325               | A4   | Infinium 670k   | WG1234567               | D1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 30.0          | 25/30           | FFFF             | Pass | OK               | started   | Blood      | CCC326             | CCC326               | B4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 31.0          | 26/30           | FFFF             | Pass | OK               | started   | Blood      | CCC327             | CCC327               | C4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 32.0          | 27/30           | FFFF             | Pass | Weak             | started   | Blood      | CCC328             | CCC328               | D4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 33.0          | 28/30           | FFFF             | Pass | OK               | started   | Blood      | CCC329             | CCC329               | E4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 34.0          | 29/30           | FFFF             | Pass | OK               | started   | Blood      | CCC330             | CCC330               | F4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 35.0          | 0/30            | FFFF             | Pass | OK               | started   | Blood      | CCC331             | CCC331               | G4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 36.0          | 1/30            | FFFF             | Pass | OK               | started   | Blood      | CCC332             | CCC332               | H4   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 37.0          | 2/30            | FFFF             | Pass | OK               | passed    | Blood      | CCC333             | CCC333               | A5   | Infinium 670k   | WG1234567               | E1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 38.0          | 3/30            | FFFF             | Pass | OK               | started   | Blood      | CCC334             | CCC334               | B5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 39.0          | 4/30            | FFFF             | Pass | OK               | started   | Blood      | CCC335             | CCC335               | C5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 40.0          | 5/30            | FFFF             | Pass | OK               | started   | Blood      | CCC336             | CCC336               | D5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 41.0          | 6/30            | FFFF             | Pass | Degraded         | started   | Blood      | CCC337             | CCC337               | E5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 42.0          | 7/30            | FFFF             | Pass | OK               | started   | Blood      | CCC338             | CCC338               | F5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 43.0          | 8/30            | FFFF             | Pass | OK               | started   | Blood      | CCC339             | CCC339               | G5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 44.0          | 9/30            | FFFF             | Pass | OK               | started   | Blood      | CCC340             | CCC340               | H5   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 45.0          | 10/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC341             | CCC341               | A6   | Infinium 670k   | WG1234567               | F1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 46.0          | 11/30           | FFFF             | Pass | OK               | started   | Blood      | CCC342             | CCC342               | B6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 47.0          | 12/30           | FFFF             | Pass | OK               | started   | Blood      | CCC343             | CCC343               | C6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 48.0          | 13/30           | FFFF             | Pass | OK               | started   | Blood      | CCC344             | CCC344               | D6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 49.0          | 14/30           | FFFF             | Pass | OK               | started   | Blood      | CCC345             | CCC345               | E6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 50.0          | 15/30           | FFFF             | Pass | OK               | started   | Blood      | CCC346             | CCC346               | F6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 51.0          | 16/30           | FFFF             | Pass | OK               | started   | Blood      | CCC347             | CCC347               | G6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 52.0          | 17/30           | FFFF             | Pass | OK               | started   | Blood      | CCC348             | CCC348               | H6   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 53.0          | 18/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC349             | CCC349               | A7   | Infinium 670k   | WG1234567               | G1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 54.0          | 19/30           | FFFF             | Pass | OK               | started   | Blood      | CCC350             | CCC350               | B7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 5.0           | 20/30           | FFFF             | Pass | OK               | started   | Blood      | CCC351             | CCC351               | C7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 6.0           | 21/30           | FFFF             | Pass | OK               | started   | Blood      | CCC352             | CCC352               | D7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 7.0           | 22/30           | FFFF             | Pass | OK               | started   | Blood      | CCC353             | CCC353               | E7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 8.0           | 23/30           | FFFF             | Pass | OK               | started   | Blood      | CCC354             | CCC354               | F7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 9.0           | 24/30           | FFFF             | Pass | OK               | started   | Blood      | CCC355             | CCC355               | G7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 10.0          | 25/30           | FFFF             | Pass | OK               | started   | Blood      | CCC356             | CCC356               | H7   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 11.0          | 26/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC357             | CCC357               | A8   | Infinium 670k   | WG1234567               | H1              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 12.0          | 27/30           | FFFF             | Pass | OK               | started   | Blood      | CCC358             | CCC358               | B8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 13.0          | 28/30           | FFFF             | Pass | OK               | started   | Blood      | CCC359             | CCC359               | C8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 14.0          | 29/30           | FFFF             | Pass | OK               | started   | Blood      | CCC360             | CCC360               | D8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 15.0          | 0/30            | FFFF             | Pass | OK               | started   | Blood      | CCC361             | CCC361               | E8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 16.0          | 1/30            | FFFF             | Pass | OK               | started   | Blood      | CCC362             | CCC362               | F8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 17.0          | 2/30            | FFFF             | Pass | OK               | started   | Blood      | CCC363             | CCC363               | G8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 18.0          | 3/30            | FFFF             | Pass | OK               | started   | Blood      | CCC364             | CCC364               | H8   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 19.0          | 4/30            | FFFF             | Pass | OK               | passed    | Blood      | CCC365             | CCC365               | A9   | Infinium 670k   | WG1234567               | A2              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 20.0          | 5/30            | FFFF             | Pass | OK               | started   | Blood      | CCC366             | CCC366               | B9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 21.0          | 6/30            | FFFF             | Pass | OK               | started   | Blood      | CCC367             | CCC367               | C9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 22.0          | 7/30            | FFFF             | Pass | OK               | started   | Blood      | CCC368             | CCC368               | D9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 23.0          | 8/30            | FFFF             | Pass | OK               | started   | Blood      | CCC369             | CCC369               | E9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 24.0          | 9/30            | FFFF             | Pass | OK               | started   | Blood      | CCC370             | CCC370               | F9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 25.0          | 10/30           | FFFF             | Pass | OK               | started   | Blood      | CCC371             | CCC371               | G9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 26.0          | 11/30           | FFFF             | Pass | OK               | started   | Blood      | CCC372             | CCC372               | H9   |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 27.0          | 12/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC373             | CCC373               | A10  | Infinium 670k   | WG1234567               | B2              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 28.0          | 13/30           | FFFF             | Pass | OK               | started   | Blood      | CCC374             | CCC374               | B10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 29.0          | 14/30           | FFFF             | Pass | OK               | started   | Blood      | CCC375             | CCC375               | C10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 30.0          | 15/30           | FFFF             | Pass | OK               | started   | Blood      | CCC376             | CCC376               | D10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 31.0          | 16/30           | FFFF             | Pass | OK               | started   | Blood      | CCC377             | CCC377               | E10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 32.0          | 17/30           | FFFF             | Pass | OK               | started   | Blood      | CCC378             | CCC378               | F10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 33.0          | 18/30           | FFFF             | Pass | OK               | started   | Blood      | CCC379             | CCC379               | G10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 34.0          | 19/30           | FFFF             | Pass | OK               | started   | Blood      | CCC380             | CCC380               | H10  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 35.0          | 20/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC381             | CCC381               | A11  | Infinium 670k   | WG1234567               | C2              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 36.0          | 21/30           | FFFF             | Pass | OK               | started   | Blood      | CCC382             | CCC382               | B11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 37.0          | 22/30           | FFFF             | Pass | OK               | started   | Blood      | CCC383             | CCC383               | C11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 38.0          | 23/30           | FFFF             | Pass | OK               | started   | Blood      | CCC384             | CCC384               | D11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 39.0          | 24/30           | FFFF             | Pass | OK               | started   | Blood      | CCC385             | CCC385               | E11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 40.0          | 25/30           | FFFF             | Pass | OK               | started   | Blood      | CCC386             | CCC386               | F11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 41.0          | 26/30           | FFFF             | Pass | OK               | started   | Blood      | CCC387             | CCC387               | G11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 42.0          | 27/30           | FFFF             | Pass | OK               | started   | Blood      | CCC388             | CCC388               | H11  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 43.0          | 28/30           | FFFF             | Pass | OK               | passed    | Blood      | CCC389             | CCC389               | A12  | Infinium 670k   | WG1234567               | D2              | 99999              |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 44.0          | 29/30           | FFFF             | Pass | OK               | started   | Blood      | CCC390             | CCC390               | B12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 45.0          | 0/30            | FFFF             | Pass | OK               | started   | Blood      | CCC391             | CCC391               | C12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 46.0          | 1/30            | FFFF             | Pass | OK               | started   | Blood      | CCC392             | CCC392               | D12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 47.0          | 2/30            | FFFF             | Pass | OK               | started   | Blood      | CCC393             | CCC393               | E12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 48.0          | 3/30            | FFFF             | Pass | OK               | started   | Blood      | CCC394             | CCC394               | F12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 49.0          | 4/30            | FFFF             | Pass | OK               | started   | Blood      | CCC395             | CCC395               | G12  |                 |                             |                 |                    |
    | Test study | Test supplier name | 1234567 | 0               | Female          | 50.0          | 5/30            | FFFF             | Pass | OK               | started   | Blood      | CCC396             | CCC396               | H12  |                 |                             |                 |                    |
   And each sample name and sanger ID exists in study "Test study"
