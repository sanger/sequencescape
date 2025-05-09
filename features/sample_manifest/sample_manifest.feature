@sample @manifest @barcode-service
Feature: Sample manifest
  In order to request genotyping on samples
  As a collaborator
  I want to be able to insert manually a list of samples
  So that Lab Technicians know what to expect to work with
  And be able to track progress of work
  And keep cost under control

  Background:
    Given I am an "External" user logged in as "john"
    And the configuration exists for creating sample manifest Excel spreadsheets
    And the Saphyr tube purpose exists
    And the "1D Tube" barcode printer "xyz1d" exists
    And the Baracoda barcode service returns "SQPD-1234567"
    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for plates"

  Scenario: Create a tube manifest and print just the first barcode when selecting option Only First Label
    When I follow "Create manifest for tubes"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Default Tube" from "Template"
    And I select "Standard sample" from "Purpose"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz1d" from "Barcode printer"
    And I fill in the field labeled "Tubes required" with "2"
    And I check "Print only the first label"
    And Pmb has the required label templates
    And Pmb is up and running
    When I press "Create manifest and print labels"
    And I should see "Your 1 label(s) have been sent to printer xyz1d"

  Scenario: Create a tube manifest and print a 2D barcode
    When I follow "Create manifest for tubes"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Default Tube" from "Template"
    And I select "Standard sample" from "Purpose"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz1d" from "Barcode printer"
    And I fill in the field labeled "Tubes required" with "1"
    And I check "Print only the first label"
    And I select "2D Barcode (with human readable barcode encoded)" from "Barcode type"
    And Pmb has the required label templates
    And Pmb is up and running
    When I press "Create manifest and print labels"
    And I should see "Your 1 label(s) have been sent to printer xyz1d"

  Scenario: Create a tube manifest and print all the barcodes
    When I follow "Create manifest for tubes"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Default Tube" from "Template"
    And I select "Standard sample" from "Purpose"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz1d" from "Barcode printer"
    And I fill in the field labeled "Tubes required" with "2"
    And Pmb has the required label templates
    And Pmb is up and running
    When I press "Create manifest and print labels"
    And I should see "Your 2 label(s) have been sent to printer xyz1d"

  @asset_type
  Scenario: Create a manifest without passing in an asset type
    When I visit the sample manifest new page without an asset type
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Default Plate" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz1d" from "Barcode printer"
    And I fill in the field labeled "Count" with "1"
    When I press "Create manifest and print labels"
    Then I should see "Manifest "
    When I follow "View all manifests"
    Then I should see "Sample Manifests"
    Then I should see the manifest table:
      | Contains    | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 1 plate     | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |

  Scenario: Create a manifest then upload an excel file instead of a csv file
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "data/sample_information.xls"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |
    And I should see "File extension is unsupported; should be csv or xlsx"
    When I follow "Manifest for Test study"
    Then I should not see "Download Completed Manifest"

  @stock_plate
  Scenario: A plate should have a purpose of stock
    Given a manifest has been created for "Test study"
    Then plate "SQPD-1234567" should have a purpose of "Stock Plate"

  Scenario: Upload a manifest that has mismatched welle
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/manifests/mismatched_wells.csv"
    And I press "Upload manifest"
    Then I should see "Sample cannot be moved between wells"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload          | Errors | State                 | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest |        |  No manifest uploaded | john       |

  Scenario: Upload a manifest that has mismatched plates
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/manifests/mismatched_plate.csv"
    And I press "Upload manifest"
    Then I should see "Sanger plate barcode has been modified, but it is not a valid foreign barcode format"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload          | Errors | State                 | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest |        |  No manifest uploaded | john       |

  Scenario: Upload a csv manifest with empty samples
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed | john       |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | sample_absent | sample_taxon_id | donor_id |
      | sample_1         | aaaa          | false         | 9606            | 12345    |
      | sample_2         | bbbb          | false         | 9607            | 12345    |
      | sample_3         | Water         | false         | 9608            | 12345    |
      | sample_4         | cccc          | false         | 9609            | 12345    |
      | sample_5         | Blank         | false         | 9610            | 12345    |
      | sample_6         | dddd          | false         | 9611            | 12345    |
      | sample_7         |               | true          |                 |          |
      | sample_8         | eeee          | false         | 9613            | 12345    |
      | sample_9         | EMPTY         | false         | 9614            | 12345    |
      | sample_10        | ffffff        | false         | 9615            | 12345    |
      | sample_11        | None          | false         | 9616            | 12345    |
      | sample_12        | gggg          | false         | 9617            | 12345    |
    Given plate "SQPD-1234567" has samples with known sanger_sample_ids
    Given I am on the Qc reports homepage
    Then I should see "New report for"
    When I select "Test study" from "Study"
    And I press "Submit"
    Then I should see "Report being generated"
    Then I should see qc reports table:
      | Study      | Created by | Download   | Rerun |
      | Test study | john       | Processing |       |
    Given 1 pending delayed jobs are processed
    And I am on the Qc reports homepage
    Then I should see qc reports table:
      | Study      | Created by | Download | Rerun |
      | Test study | john        | Download | Rerun |
    Then I follow "Download report for Test study"
    Then I should see the report for "Test study":
     | Supplier Sample Name |  Sanger Sample Name | Plate   | Well |
     |                      |                     | SQPD-1234567 | A1   |
     | aaaa                 |  ABC_1              | SQPD-1234567 | B1   |
     | bbbb                 |  ABC_2              | SQPD-1234567 | C1   |
     | Water                |  ABC_3              | SQPD-1234567 | D1   |
     | cccc                 |  ABC_4              | SQPD-1234567 | E1   |
     | Blank                |  ABC_5              | SQPD-1234567 | F1   |
     | dddd                 |  ABC_6              | SQPD-1234567 | G1   |
     |                      |                     | SQPD-1234567 | H1   |
     | eeee                 |  ABC_8              | SQPD-1234567 | A2   |
     | EMPTY                |  ABC_9              | SQPD-1234567 | B2   |
     | ffffff               |  ABC_10             | SQPD-1234567 | C2   |
     | None                 |  ABC_11             | SQPD-1234567 | D2   |
     | gggg                 |  ABC_12             | SQPD-1234567 | E2   |
     |                      |                     | SQPD-1234567 | F2   |
     |                      |                     | SQPD-1234567 | G2   |
     |                      |                     | SQPD-1234567 | H2   |
     |                      |                     | SQPD-1234567 | A3   |
     |                      |                     | SQPD-1234567 | B3   |
     |                      |                     | SQPD-1234567 | C3   |
     |                      |                     | SQPD-1234567 | D3   |
     |                      |                     | SQPD-1234567 | E3   |
     |                      |                     | SQPD-1234567 | F3   |
     |                      |                     | SQPD-1234567 | G3   |
     |                      |                     | SQPD-1234567 | H3   |
     |                      |                     | SQPD-1234567 | A4   |
     |                      |                     | SQPD-1234567 | B4   |
     |                      |                     | SQPD-1234567 | C4   |
     |                      |                     | SQPD-1234567 | D4   |
     |                      |                     | SQPD-1234567 | E4   |
     |                      |                     | SQPD-1234567 | F4   |
     |                      |                     | SQPD-1234567 | G4   |
     |                      |                     | SQPD-1234567 | H4   |
     |                      |                     | SQPD-1234567 | A5   |
     |                      |                     | SQPD-1234567 | B5   |
     |                      |                     | SQPD-1234567 | C5   |
     |                      |                     | SQPD-1234567 | D5   |
     |                      |                     | SQPD-1234567 | E5   |
     |                      |                     | SQPD-1234567 | F5   |
     |                      |                     | SQPD-1234567 | G5   |
     |                      |                     | SQPD-1234567 | H5   |
     |                      |                     | SQPD-1234567 | A6   |
     |                      |                     | SQPD-1234567 | B6   |
     |                      |                     | SQPD-1234567 | C6   |
     |                      |                     | SQPD-1234567 | D6   |
     |                      |                     | SQPD-1234567 | E6   |
     |                      |                     | SQPD-1234567 | F6   |
     |                      |                     | SQPD-1234567 | G6   |
     |                      |                     | SQPD-1234567 | H6   |
     |                      |                     | SQPD-1234567 | A7   |
     |                      |                     | SQPD-1234567 | B7   |
     |                      |                     | SQPD-1234567 | C7   |
     |                      |                     | SQPD-1234567 | D7   |
     |                      |                     | SQPD-1234567 | E7   |
     |                      |                     | SQPD-1234567 | F7   |
     |                      |                     | SQPD-1234567 | G7   |
     |                      |                     | SQPD-1234567 | H7   |
     |                      |                     | SQPD-1234567 | A8   |
     |                      |                     | SQPD-1234567 | B8   |
     |                      |                     | SQPD-1234567 | C8   |
     |                      |                     | SQPD-1234567 | D8   |
     |                      |                     | SQPD-1234567 | E8   |
     |                      |                     | SQPD-1234567 | F8   |
     |                      |                     | SQPD-1234567 | G8   |
     |                      |                     | SQPD-1234567 | H8   |
     |                      |                     | SQPD-1234567 | A9   |
     |                      |                     | SQPD-1234567 | B9   |
     |                      |                     | SQPD-1234567 | C9   |
     |                      |                     | SQPD-1234567 | D9   |
     |                      |                     | SQPD-1234567 | E9   |
     |                      |                     | SQPD-1234567 | F9   |
     |                      |                     | SQPD-1234567 | G9   |
     |                      |                     | SQPD-1234567 | H9   |
     |                      |                     | SQPD-1234567 | A10  |
     |                      |                     | SQPD-1234567 | B10  |
     |                      |                     | SQPD-1234567 | C10  |
     |                      |                     | SQPD-1234567 | D10  |
     |                      |                     | SQPD-1234567 | E10  |
     |                      |                     | SQPD-1234567 | F10  |
     |                      |                     | SQPD-1234567 | G10  |
     |                      |                     | SQPD-1234567 | H10  |
     |                      |                     | SQPD-1234567 | A11  |
     |                      |                     | SQPD-1234567 | B11  |
     |                      |                     | SQPD-1234567 | C11  |
     |                      |                     | SQPD-1234567 | D11  |
     |                      |                     | SQPD-1234567 | E11  |
     |                      |                     | SQPD-1234567 | F11  |
     |                      |                     | SQPD-1234567 | G11  |
     |                      |                     | SQPD-1234567 | H11  |
     |                      |                     | SQPD-1234567 | A12  |
     |                      |                     | SQPD-1234567 | B12  |
     |                      |                     | SQPD-1234567 | C12  |
     |                      |                     | SQPD-1234567 | D12  |
     |                      |                     | SQPD-1234567 | E12  |
     |                      |                     | SQPD-1234567 | F12  |
     |                      |                     | SQPD-1234567 | G12  |
     |                      |                     | SQPD-1234567 | H12  |

  @cell_line
  Scenario: Upload a manifest with invalid cell line
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_dna_sources_invalid.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload           | Errors  | State                |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest  |         | No manifest uploaded |
    And I should see "DNA source is not included in the list"

  @cell_line
  Scenario: Upload a manifest with invalid cell line
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_dna_sources_valid.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload              | Errors   | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest  |          | Completed |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | dna_source |
      | sample_1         | a             | Cell Line                      |
      | sample_2         | b             | Blood                          |
      | sample_3         | c             | Genomic                        |
      | sample_4         | d             | Amniocentesis Cultured         |


  @override
  Scenario: Upload some empty samples, reupload with samples but without override set
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | sample_absent | sample_taxon_id |
      | sample_1         | aaaa          | false         | 9606            |
      | sample_2         | bbbb          | false         | 9607            |
      | sample_3         | Water         | false         | 9608            |
      | sample_4         | cccc          | false         | 9609            |
      | sample_5         | Blank         | false         | 9610            |
      | sample_6         | dddd          | false         | 9611            |
      | sample_7         |               | true          |                 |
      | sample_8         | eeee          | false         | 9613            |
      | sample_9         | EMPTY         | false         | 9614            |
      | sample_10        | ffffff        | false         | 9615            |
      | sample_11        | None          | false         | 9616            |
      | sample_12        | gggg          | false         | 9617            |

    When I follow "Manifest for Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells_with_no_blanks.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | sample_absent | sample_taxon_id | sample_common_name  |
      | sample_1         | aaaa          | false         | 9606            | Human  |
      | sample_2         | bbbb          | false         | 9607            | Human  |
      | sample_3         | Water         | false         | 9608            | Human  |
      | sample_4         | cccc          | false         | 9609            | Human  |
      | sample_5         | Blank         | false         | 9610            | Human  |
      | sample_6         | dddd          | false         | 9611            | Human  |
      | sample_7         | xxxx          | false         | 10012           | Human  |
      | sample_8         | eeee          | false         | 9613            | Human  |
      | sample_9         | EMPTY         | false         | 9614            | Human  |
      | sample_10        | ffffff        | false         | 9615            | Human  |
      | sample_11        | None          | false         | 9616            | Human  |
      | sample_12        | gggg          | false         | 9617            | Human  |

  @override
  Scenario: Upload some empty samples, reupload with samples but with override set
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
     | sanger_sample_id | supplier_name | sample_absent | sample_taxon_id |
     | sample_1         | aaaa          | false         | 9606            |
     | sample_2         | bbbb          | false         | 9607            |
     | sample_3         | Water         | false         | 9608            |
     | sample_4         | cccc          | false         | 9609            |
     | sample_5         | Blank         | false         | 9610            |
     | sample_6         | dddd          | false         | 9611            |
     | sample_7         |               | true          |                 |
     | sample_8         | eeee          | false         | 9613            |
     | sample_9         | EMPTY         | false         | 9614            |
     | sample_10        | ffffff        | false         | 9615            |
     | sample_11        | None          | false         | 9616            |
     | sample_12        | gggg          | false         | 9617            |

    When I follow "Manifest for Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells_with_no_blanks.csv"
    And I check "Override previously uploaded samples"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
     | sanger_sample_id | supplier_name  | sample_absent | sample_taxon_id |
     | sample_1         | aaaa_updated   | false                      | 9606            |
     | sample_2         | bbbb           | false                      | 9607            |
     | sample_3         | zzzzz          | false                      | 9608            |
     | sample_4         | cccc           | false                      | 9609            |
     | sample_5         | yyyyy          | false                      | 9610            |
     | sample_6         | dddd           | false                      | 9611            |
     | sample_7         | xxxx           | false                      | 10012           |
     | sample_8         | eeee_updated   | false                      | 10013           |
     | sample_9         | wwwww          | false                      | 10014           |
     | sample_10        | ffffff_updated | false                      | 10015           |
     | sample_11        | uuuuu          | false                      | 10016           |
     | sample_12        | gggg_updated   | false                      | 10017           |

 @override
  Scenario Outline: Updating of sample accession numbers
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/<initial>"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    When I follow "Manifest for Test study"
    When I fill in "File to upload" with the file "test/data/<update>"
    And I check "Override previously uploaded samples"
    And I press "Upload manifest"
    Then I should see "<message>"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | State   |
      | 1 plate  | Test study | Test supplier name | Blank manifest | <state> |
    Then the sample accession numbers should be:
     | sanger_sample_id | accession_number |
     | sample_1         | 12345            |
     | sample_2         | 12346            |
     | sample_3         | 12347            |
     | sample_4         | 12348            |
     | sample_5         | 12349            |
     | sample_6         | 12350            |
     | sample_7         | 12351            |
     | sample_8         | 12352            |
     | sample_9         | 12353            |
     | sample_10        | 12354            |
     | sample_11        | 12355            |
     | sample_12        | 12356            |

    Examples:
      | initial                           | update                            | state     | message                                                           |
      | sample_manifest_a_accessions.csv  | sample_manifest_no_accessions.csv | Completed | Sample manifest successfully uploaded                             |
      | sample_manifest_a_accessions.csv  | sample_manifest_b_accessions.csv  | Failed    | The accession number does not match the existing accession number |
      | sample_manifest_no_accessions.csv | sample_manifest_a_accessions.csv  | Completed | Sample manifest successfully uploaded                             |

@override
  Scenario: Setting of reference_genomes
    Given a manifest has been created for "Test study"
    And the reference genome "Dragon" exists
    And the reference genome "Centaur" exists
    When I fill in "File to upload" with the file "test/data/sample_manifest_reference_genomes.csv"
    And I press "Upload manifest"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the sample reference genomes should be:
     | sanger_sample_id | reference_genome |
     | sample_1         | Dragon           |
     | sample_2         | Dragon           |
     | sample_3         | Dragon           |
     | sample_4         | Dragon           |
     | sample_5         | Dragon           |
     | sample_6         | Centaur          |
     | sample_7         | Centaur          |
     | sample_8         | Centaur          |
     | sample_9         | Centaur          |
     | sample_10        | Centaur          |
     | sample_11        | Centaur          |
     | sample_12        | Centaur          |

  @override
  Scenario: Using an invalid reference genome
    Given a manifest has been created for "Test study"
    And the reference genome "Dragon" exists
    When I fill in "File to upload" with the file "test/data/sample_manifest_reference_genomes.csv"
    And I press "Upload manifest"
    Then I should see "could not find Centaur reference genome"
