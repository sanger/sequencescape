@sample @manifest @barcode-service
Feature: Full sample manifest
  In order to populate all metadata
  I need to be able to use the full manifest template
  Without invalid header errors

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

  Scenario: Create a plate manifest and upload a manifest file and process it
    Given a manifest has been created for "Test study"
    When I fill in "File to upload" with the file "test/data/full_manifest.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I follow "View all manifests"
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload              | Errors | State   | Created by |
      | 1 plate  | Test study | Test supplier name | Blank manifest | Completed manifest  |        | Completed | john       |
    When I follow "Manifest for Test study"
    Then I should see "DN1234567T"

    Then the samples table should look like:
      | sanger_sample_id | supplier_name | empty_supplier_sample_name | sample_taxon_id | cell_type  |
      | sample_1         | aaaa          | false                      | 9606            | Epithelial |
      | sample_2         | bbbb          | false                      | 9606            | Epithelial |
      | sample_3         | cccc          | false                      | 9606            | Epithelial |
      | sample_4         | dddd          | false                      | 9606            | Epithelial |
      | sample_5         | eeee          | false                      | 9606            | Epithelial |
      | sample_6         | ffff          | false                      | 9606            | Epithelial |
      | sample_7         | gggg          | false                      | 9606            | Epithelial |
      | sample_8         | hhhh          | false                      | 9606            | Epithelial |
      | sample_9         | iiii          | false                      | 9606            | Epithelial |
      | sample_10        | jjjj          | false                      | 9606            | Epithelial |
      | sample_11        | kkkk          | false                      | 9606            | Epithelial |
      | sample_12        | llll          | false                      | 9606            | Epithelial |
