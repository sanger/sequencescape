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
    And the "96 Well Plate" barcode printer "xyz" exists
    And the plate barcode webservice returns "1234567"
    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for plates"

  Scenario: Create a plate manifest and upload a manifest file without processing it
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload              | Errors | State   | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest  |        | Pending | john       |
    When I follow "Manifest for Test study"
    Then I should see "DN1234567T"

  @asset_type
  Scenario: Create a manifest without passing in an asset type
    When I visit the sample manifest new page without an asset type
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "default layout" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz" from "Barcode printer"
    And I select "default layout" from "Template"
    And I fill in the field labeled "Count" with "1"
    When I press "Create manifest and print labels"
    Then I should see "Manifest_"
    When I follow "View all manifests"
    Then I should see "Sample Manifests"
    Then I should see the manifest table:
      | Contains    | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 1 plate     | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |

  Scenario: Create a manifest then upload an excel file instead of a csv file
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "data/base_manifest.xls"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |
    And I should see "Invalid CSV file"

  Scenario: Create a 1D tube manifest without processing the manifest
    When I follow "Create manifest for 1D tubes"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "default tube layout" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz" from "Barcode printer"
    And I fill in the field labeled "Count" with "10"
    When I press "Create manifest and print labels"
    Then I should see "Manifest_"
    Then I should see "Download Blank Manifest"
    Given 3 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see "Sample Manifests"
    Then I should see "Upload a sample manifest"
    And study "Test study" should have 10 samples
    Then I should see the manifest table:
      | Contains    | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 10 1dtubes  | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |

  @stock_plate
  Scenario: A plate should have a purpose of stock
    Given a manifest has been created for "Test study"
    Then plate "1234567" should have a purpose of "Stock Plate"

  Scenario Outline: Upload a manifest that has mismatched information
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "<filename>"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload          | Errors | State  | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest | Errors | Failed | john       |
    When I follow "Errors for manifest for Test study"
    And I should see "Well info for sample_1 mismatch: expected DN1234567T B1 but reported as <barcode> <well>"

    Scenarios:
      | filename                                 | barcode    | well |
      | test/data/manifests/mismatched_wells.csv | DN1234567T | A1   |
      | test/data/manifests/mismatched_plate.csv | DN11111T   | B1   |

  Scenario: Upload a csv manifest with empty samples
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed | john       |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id | donor_id |
      | sample_1         | aaaa          | false                      | 9606            | 12345    |
      | sample_2         | bbbb          | false                      | 9607            | 12345    |
      | sample_3         | Water         | true                       |                 |          |
      | sample_4         | cccc          | false                      | 9609            | 12345    |
      | sample_5         | Blank         | true                       |                 |          |
      | sample_6         | dddd          | false                      | 9611            | 12345    |
      | sample_7         |               | true                       |                 |          |
      | sample_8         | eeee          | false                      | 9613            | 12345    |
      | sample_9         | EMPTY         | true                       |                 |          |
      | sample_10        | ffffff        | false                      | 9615            | 12345    |
      | sample_11        | None          | true                       |                 |          |
      | sample_12        | gggg          | false                      | 9617            | 12345    |
    Given plate "1234567" has samples with known sanger_sample_ids
    Given I am on the Qc reports homepage
    Then I should see "New report for"
    When I select "Test study" from "Study"
    And I press "Submit"
    Then I should see "Report being generated"
    Then I should see qc reports table:
      | Study      | Created by | Download   | Rerun |
      | Test study | john        | Processing |       |
    Given 1 pending delayed jobs are processed
    And I am on the Qc reports homepage
    Then I should see qc reports table:
      | Study      | Created by | Download | Rerun |
      | Test study | john        | Download | Rerun |
    Then I follow "Download report for Test study"
    Then I should see the report for "Test study":
     | Supplier Sample Name |  Sanger Sample Name | Plate   | Well |
     | ABC_0                |  ABC_0              | 1234567 | A1   |
     | aaaa                 |  ABC_1              | 1234567 | B1   |
     | bbbb                 |  ABC_2              | 1234567 | C1   |
     | Blank                |  ABC_3              | 1234567 | D1   |
     | cccc                 |  ABC_4              | 1234567 | E1   |
     | Blank                |  ABC_5              | 1234567 | F1   |
     | dddd                 |  ABC_6              | 1234567 | G1   |
     | Blank                |  ABC_7              | 1234567 | H1   |
     | eeee                 |  ABC_8              | 1234567 | A2   |
     | Blank                |  ABC_9              | 1234567 | B2   |
     | ffffff               |  ABC_10             | 1234567 | C2   |
     | Blank                |  ABC_11             | 1234567 | D2   |
     | gggg                 |  ABC_12             | 1234567 | E2   |
     | ABC_13               |  ABC_13             | 1234567 | F2   |
     | ABC_14               |  ABC_14             | 1234567 | G2   |
     | ABC_15               |  ABC_15             | 1234567 | H2   |
     | ABC_16               |  ABC_16             | 1234567 | A3   |
     | ABC_17               |  ABC_17             | 1234567 | B3   |
     | ABC_18               |  ABC_18             | 1234567 | C3   |
     | ABC_19               |  ABC_19             | 1234567 | D3   |
     | ABC_20               |  ABC_20             | 1234567 | E3   |
     | ABC_21               |  ABC_21             | 1234567 | F3   |
     | ABC_22               |  ABC_22             | 1234567 | G3   |
     | ABC_23               |  ABC_23             | 1234567 | H3   |
     | ABC_24               |  ABC_24             | 1234567 | A4   |
     | ABC_25               |  ABC_25             | 1234567 | B4   |
     | ABC_26               |  ABC_26             | 1234567 | C4   |
     | ABC_27               |  ABC_27             | 1234567 | D4   |
     | ABC_28               |  ABC_28             | 1234567 | E4   |
     | ABC_29               |  ABC_29             | 1234567 | F4   |
     | ABC_30               |  ABC_30             | 1234567 | G4   |
     | ABC_31               |  ABC_31             | 1234567 | H4   |
     | ABC_32               |  ABC_32             | 1234567 | A5   |
     | ABC_33               |  ABC_33             | 1234567 | B5   |
     | ABC_34               |  ABC_34             | 1234567 | C5   |
     | ABC_35               |  ABC_35             | 1234567 | D5   |
     | ABC_36               |  ABC_36             | 1234567 | E5   |
     | ABC_37               |  ABC_37             | 1234567 | F5   |
     | ABC_38               |  ABC_38             | 1234567 | G5   |
     | ABC_39               |  ABC_39             | 1234567 | H5   |
     | ABC_40               |  ABC_40             | 1234567 | A6   |
     | ABC_41               |  ABC_41             | 1234567 | B6   |
     | ABC_42               |  ABC_42             | 1234567 | C6   |
     | ABC_43               |  ABC_43             | 1234567 | D6   |
     | ABC_44               |  ABC_44             | 1234567 | E6   |
     | ABC_45               |  ABC_45             | 1234567 | F6   |
     | ABC_46               |  ABC_46             | 1234567 | G6   |
     | ABC_47               |  ABC_47             | 1234567 | H6   |
     | ABC_48               |  ABC_48             | 1234567 | A7   |
     | ABC_49               |  ABC_49             | 1234567 | B7   |
     | ABC_50               |  ABC_50             | 1234567 | C7   |
     | ABC_51               |  ABC_51             | 1234567 | D7   |
     | ABC_52               |  ABC_52             | 1234567 | E7   |
     | ABC_53               |  ABC_53             | 1234567 | F7   |
     | ABC_54               |  ABC_54             | 1234567 | G7   |
     | ABC_55               |  ABC_55             | 1234567 | H7   |
     | ABC_56               |  ABC_56             | 1234567 | A8   |
     | ABC_57               |  ABC_57             | 1234567 | B8   |
     | ABC_58               |  ABC_58             | 1234567 | C8   |
     | ABC_59               |  ABC_59             | 1234567 | D8   |
     | ABC_60               |  ABC_60             | 1234567 | E8   |
     | ABC_61               |  ABC_61             | 1234567 | F8   |
     | ABC_62               |  ABC_62             | 1234567 | G8   |
     | ABC_63               |  ABC_63             | 1234567 | H8   |
     | ABC_64               |  ABC_64             | 1234567 | A9   |
     | ABC_65               |  ABC_65             | 1234567 | B9   |
     | ABC_66               |  ABC_66             | 1234567 | C9   |
     | ABC_67               |  ABC_67             | 1234567 | D9   |
     | ABC_68               |  ABC_68             | 1234567 | E9   |
     | ABC_69               |  ABC_69             | 1234567 | F9   |
     | ABC_70               |  ABC_70             | 1234567 | G9   |
     | ABC_71               |  ABC_71             | 1234567 | H9   |
     | ABC_72               |  ABC_72             | 1234567 | A10  |
     | ABC_73               |  ABC_73             | 1234567 | B10  |
     | ABC_74               |  ABC_74             | 1234567 | C10  |
     | ABC_75               |  ABC_75             | 1234567 | D10  |
     | ABC_76               |  ABC_76             | 1234567 | E10  |
     | ABC_77               |  ABC_77             | 1234567 | F10  |
     | ABC_78               |  ABC_78             | 1234567 | G10  |
     | ABC_79               |  ABC_79             | 1234567 | H10  |
     | ABC_80               |  ABC_80             | 1234567 | A11  |
     | ABC_81               |  ABC_81             | 1234567 | B11  |
     | ABC_82               |  ABC_82             | 1234567 | C11  |
     | ABC_83               |  ABC_83             | 1234567 | D11  |
     | ABC_84               |  ABC_84             | 1234567 | E11  |
     | ABC_85               |  ABC_85             | 1234567 | F11  |
     | ABC_86               |  ABC_86             | 1234567 | G11  |
     | ABC_87               |  ABC_87             | 1234567 | H11  |
     | ABC_88               |  ABC_88             | 1234567 | A12  |
     | ABC_89               |  ABC_89             | 1234567 | B12  |
     | ABC_90               |  ABC_90             | 1234567 | C12  |
     | ABC_91               |  ABC_91             | 1234567 | D12  |
     | ABC_92               |  ABC_92             | 1234567 | E12  |
     | ABC_93               |  ABC_93             | 1234567 | F12  |
     | ABC_94               |  ABC_94             | 1234567 | G12  |
     | ABC_95               |  ABC_95             | 1234567 | H12  |


  @concentration @volume
  Scenario: Upload a manifest without volume or concentration set
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_no_vol_conc.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload           | Errors   | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest  | Errors   | Failed |
    When I follow "Errors for manifest for Test study"
    Then I should not see "Volume can't be blank for sample_1"
    And I should see "Volume can't be blank for sample_2"
    Then I should not see "Concentration can't be blank for sample_1"
    And I should see "Concentration can't be blank for sample_3"

  @cell_line
  Scenario: Upload a manifest with invalid cell line
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_dna_sources_invalid.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload           | Errors   | State  |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Upload manifest  | Errors   | Failed |
    When I follow "Errors for manifest for Test study"
    Then I should see "Dna source is not included in the list"

  @cell_line
  Scenario: Upload a manifest with invalid cell line
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_dna_sources_valid.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload              | Errors   | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest  |          | Completed |

  @is_control
  Scenario: Check is_control and is_resubmit are set properly in an uploaded manifest
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_is_control_is_resubmit.csv"
    And I press "Upload manifest"
    Given the manifests are successfully processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the sample controls and resubmits should look like:
      | sanger_sample_id | supplier_name | is_control | is_resubmit |
      | sample_1         | a             | false      | true        |
      | sample_2         | b             | false      | true        |
      | sample_3         | c             | false      | true        |
      | sample_4         | d             | false      | true        |
      | sample_5         | e             | true       | false       |
      | sample_6         | f             | true       | false       |
      | sample_7         | g             | true       | false       |
      | sample_8         | h             | true       | false       |


  @override
  Scenario: Upload some empty samples, reupload with samples but without override set
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id |
      | sample_1         | aaaa          | false                      | 9606            |
      | sample_2         | bbbb          | false                      | 9607            |
      | sample_3         | Water         | true                       |                 |
      | sample_4         | cccc          | false                      | 9609            |
      | sample_5         | Blank         | true                       |                 |
      | sample_6         | dddd          | false                      | 9611            |
      | sample_7         |               | true                       |                 |
      | sample_8         | eeee          | false                      | 9613            |
      | sample_9         | EMPTY         | true                       |                 |
      | sample_10        | ffffff        | false                      | 9615            |
      | sample_11        | None          | true                       |                 |
      | sample_12        | gggg          | false                      | 9617            |


    When I fill in "File to upload" with the file "test/data/test_blank_wells_with_no_blanks.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id | sample_common_name  |
      | sample_1         | aaaa          | false                      | 9606            | Human  |
      | sample_2         | bbbb          | false                      | 9607            | Human  |
      | sample_3         | zzzzz         | false                      | 9608            | Human  |
      | sample_4         | cccc          | false                      | 9609            | Human  |
      | sample_5         | yyyyy         | false                      | 9610            | Human  |
      | sample_6         | dddd          | false                      | 9611            | Human  |
      | sample_7         | xxxx          | false                      | 10012           | Human  |
      | sample_8         | eeee          | false                      | 9613            | Human  |
      | sample_9         | wwwww         | false                      | 10014           | Human  |
      | sample_10        | ffffff        | false                      | 9615            | Human  |
      | sample_11        | uuuuu         | false                      | 10016           | Human  |
      | sample_12        | gggg          | false                      | 9617            | Human  |


  @override
  Scenario: Upload some empty samples, reupload with samples but with override set
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/test_blank_wells.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
     | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id |
     | sample_1         | aaaa          | false                      | 9606            |
     | sample_2         | bbbb          | false                      | 9607            |
     | sample_3         | Water         | true                       |                 |
     | sample_4         | cccc          | false                      | 9609            |
     | sample_5         | Blank         | true                       |                 |
     | sample_6         | dddd          | false                      | 9611            |
     | sample_7         |               | true                       |                 |
     | sample_8         | eeee          | false                      | 9613            |
     | sample_9         | EMPTY         | true                       |                 |
     | sample_10        | ffffff        | false                      | 9615            |
     | sample_11        | None          | true                       |                 |
     | sample_12        | gggg          | false                      | 9617            |


    When I fill in "File to upload" with the file "test/data/test_blank_wells_with_no_blanks.csv"
    And I check "Override previously uploaded samples"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    Then the samples table should look like:
     | sanger_sample_id | supplier_name  | empty_supplier_sample_name | sample_taxon_id |
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
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload             | Errors | State     |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest |        | Completed |
    When I fill in "File to upload" with the file "test/data/<update>"
    And I check "Override previously uploaded samples"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Errors   | State   |
      | 1 plate  | Test study | Test supplier name | Blank manifest | <errors> | <state> |
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
      | initial                           | update                            | state     | errors |
      | sample_manifest_a_accessions.csv  | sample_manifest_no_accessions.csv | Completed |        |
      | sample_manifest_a_accessions.csv  | sample_manifest_b_accessions.csv  | Failed    | Errors |
      | sample_manifest_no_accessions.csv | sample_manifest_a_accessions.csv  | Completed |        |





