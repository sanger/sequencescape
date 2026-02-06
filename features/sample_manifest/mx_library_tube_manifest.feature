@sample @manifest @barcode-service
Feature: Sample manifest
  In order to process external libraries without creating unnecessary tubes
  As a pipeline manager
  I want to be able to be able to easily register multiplexed libraries
  in a similar manner to sample tubes

  Background:
    Given I am an "External" user logged in as "john"
    And the configuration exists for creating sample manifest Excel spreadsheets
    And the "1D Tube" barcode printer "xyz" exists
    And the library type "Standard" exists
    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    And I have a tag group called "test tag group" with 7 tags
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for multiplexed libraries"

    When I follow "Create manifest for multiplexed libraries"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Multiplexed Library Tube" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz" from "Barcode printer"
    And I fill in the field labeled "Number of samples in library" with "5"
    When I press "Create manifest and print labels"
    Then I should see "Manifest "
    Then I should see "Download Blank Manifest"
    Given 3 pending delayed jobs are processed
    And library tubes are barcoded sequentially from 81
    And library tubes are expected by the last manifest
    And I reset all of the sanger sample ids to a known number sequence
    When I follow "View all manifests"
    Then I should see "Sample Manifests"
    Then I should see "Upload a Sample Manifest"
    Then I should see the manifest table:
      | Contains                  | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 5 multiplexed_libraries   | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |

  Scenario: Create a mx manifest

    When I fill in "File to upload" with the file "test/data/multiplexed_library_manifest.csv"
    And I press "Upload manifest"
    Then print any manifest errors for debugging
    Then I should see the manifest table:
      | Contains                  | Study      | Supplier           | Manifest       | Upload              | Errors | State     | Created by |
      | 5 multiplexed_libraries   | Test study | Test supplier name | Blank manifest | Completed manifest  |        | Completed | john       |
    When I follow "Manifest for Test study"
    Then I should see "NT81M"

    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id |
      | sample_0         | aaaa          | false                      | 9606            |
      | sample_1         | bbbb          | false                      | 9606            |
      | sample_2         | cccc          | false                      | 9606            |
      | sample_3         | dddd          | false                      | 9606            |
      | sample_4         | eeee          | false                      | 9606            |

    And the samples should be tagged in library and multiplexed library tubes with:
      | tube_barcode | sanger_sample_id | tag_group      | tag_index | library_type | insert_size_from | insert_size_to | tag2_group | tag2_index |
      | NT81         | sample_0         | test tag group | 1         | Standard     | 100              | 200            |            |            |
      | NT82         | sample_1         | test tag group | 2         | Standard     | 100              | 200            |            |            |
      | NT83         | sample_2         | test tag group | 3         | Standard     | 100              | 200            |            |            |
      | NT84         | sample_3         | test tag group | 5         | Standard     | 100              | 200            |            |            |
      | NT85         | sample_4         | test tag group | 7         | Standard     | 100              | 200            |            |            |

    When I fill in "File to upload" with the file "test/data/updated_multiplexed_library_manifest.csv"
    And I check "Override previously uploaded samples"
    And I press "Upload manifest"
    Then print any manifest errors for debugging

    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id |
      | sample_0         | ffff          | false                      | 9606            |
      | sample_1         | gggg          | false                      | 9606            |
      | sample_2         | hhhh          | false                      | 9606            |
      | sample_3         | iiii          | false                      | 9606            |
      | sample_4         | jjjj          | false                      | 9606            |
    And the samples should be tagged in library and multiplexed library tubes with:
      | tube_barcode | sanger_sample_id | tag_group      | tag_index | library_type | insert_size_from | insert_size_to | tag2_group | tag2_index |
      | NT81         | sample_0         | test tag group | 7         | Standard     | 100              | 200            |            |            |
      | NT82         | sample_1         | test tag group | 5         | Standard     | 100              | 200            |            |            |
      | NT83         | sample_2         | test tag group | 3         | Standard     | 100              | 200            |            |            |
      | NT84         | sample_3         | test tag group | 2         | Standard     | 100              | 200            |            |            |
      | NT85         | sample_4         | test tag group | 1         | Standard     | 100              | 200            |            |            |


Scenario: Create a dual indexed mx manifest

    Given I have a tag group called "test tag group2" with 2 tags
    And I have a tag group called "test tag group3" with 2 tags

    When I fill in "File to upload" with the file "test/data/multiplexed_di_library_manifest.csv"
    And I press "Upload manifest"
    Then print any manifest errors for debugging
    Then I should see the manifest table:
      | Contains                  | Study      | Supplier           | Manifest       | Upload              | Errors | State     | Created by |
      | 5 multiplexed_libraries   | Test study | Test supplier name | Blank manifest | Completed manifest  |        | Completed | john       |
    When I follow "Manifest for Test study"
    Then I should see "NT81M"

    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id |
      | sample_0         | aaaa          | false                      | 9606            |
      | sample_1         | bbbb          | false                      | 9606            |
      | sample_2         | cccc          | false                      | 9606            |
      | sample_3         | dddd          | false                      | 9606            |
      | sample_4         | eeee          | false                      | 9606            |

    And the samples should be tagged in library and multiplexed library tubes with:
      | tube_barcode | sanger_sample_id | tag_group       | tag_index | tag2_group      | tag2_index | library_type | insert_size_from | insert_size_to |
      | NT81         | sample_0         | test tag group  | 1         | test tag group2 | 1          | Standard     | 100              | 200            |
      | NT82         | sample_1         | test tag group  | 2         | test tag group2 | 1          | Standard     | 100              | 200            |
      | NT83         | sample_2         | test tag group  | 3         | test tag group2 | 1          | Standard     | 100              | 200            |
      | NT84         | sample_3         | test tag group3 | 1         | test tag group2 | 1          | Standard     | 100              | 200            |
      | NT85         | sample_4         | test tag group3 | 2         | test tag group2 | 1          | Standard     | 100              | 200            |
