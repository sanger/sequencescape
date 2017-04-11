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
    And the "1D Tube" barcode printer "xyz" exists
    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for 1D tubes"

  Scenario: Create a 1D tube manifest without processing the manifest
    When I follow "Create manifest for 1D tubes"
    Then I should see "Barcode printer"
    When I select "Test study" from "Study"
    And I select "Default Tube" from "Template"
    And I select "Test supplier name" from "Supplier"
    And I select "xyz" from "Barcode printer"
    And I fill in the field labeled "Tubes required" with "5"
    When Pmb has the required label templates
    And Pmb is up and running
    And I press "Create manifest and print labels"
    Then I should see "Your 5 label(s) have been sent to printer xyz"
    Then I should see "Manifest_"
    Then I should see "Download Blank Manifest"
    Given 3 pending delayed jobs are processed
    And sample tubes are barcoded sequentially from 81
    And sample tubes are expected by the last manifest
    And I reset all of the sanger sample ids to a known number sequence
    When I follow "View all manifests"
    Then I should see "Sample Manifests"
    Then I should see "Upload a sample manifest"
    And study "Test study" should have 5 samples
    Then I should see the manifest table:
      | Contains  | Study      | Supplier           | Manifest       | Upload          | Errors | State                | Created by |
      | 5 1dtubes | Test study | Test supplier name | Blank manifest | Upload manifest |        | No manifest uploaded | john       |

    When I fill in "File to upload" with the file "test/data/tube_sample_manifest.csv"
    And I press "Upload manifest"
    Given 1 pending delayed jobs are processed
    When I refresh the page
    Then I should see the manifest table:
      | Contains | Study      | Supplier           | Manifest       | Upload              | Errors | State   | Created by |
      | 5 1dtubes | Test study | Test supplier name | Blank manifest | Completed manifest  |        | Completed | john       |
    When I follow "Manifest for Test study"
    Then I should see "NT81M"

    Then the samples table should look like:
      | sanger_sample_id      | supplier_name | empty_supplier_sample_name | sample_taxon_id |
      | tube_sample_1         | aaaa          | false                      | 9606            |
      | tube_sample_2         | bbbb          | false                      | 9606            |
      | tube_sample_3         | cccc          | false                      | 9606            |
      | tube_sample_4         | dddd          | false                      | 9606            |
      | tube_sample_5         | eeee          | false                      | 9606            |


