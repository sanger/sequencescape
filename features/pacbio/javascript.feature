@pacbio @submission @barcode-service @sample_validation_service @javascript
Feature: Push samples through the PacBio pipeline with javascript

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"
    Given I have an active study called "Test study"
    Given I am on the show page for study "Test study"
    Given the "1D Tube" barcode printer "xyz" exists
    Given the "96 Well Plate" barcode printer "abc" exists
    And the plate barcode webservice returns "99998"
    And the plate barcode webservice returns "99999"
    And the reference genome "Mouse" exists
    Given the study "Test study" has a reference genome of "Mouse"

  Scenario: Enough SMRTcells requested to cover multiple wells
    And I have a plate for PacBio in study "Test study"
    Given I have a "PacBio" submission with the following setup:
       | Project         | Test project     |
       | Study           | Test study       |
       | Asset Group     | PacBio group     |
       | Insert size     | 2000             |
       | Sequencing type | Standard         |
       | multiplier#2    | 22               |
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "PacBio Library Prep"
    When I check "Select DN1234567T for batch"
    When I press the first "Submit"
    When I follow "DNA Template Prep Kit Box Barcode"
    Given Well "1234567":"A1" has a PacBioLibraryTube "333"
    When I fill in "DNA Template Prep Kit Box Barcode" with "999"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    When I set PacBioLibraryTube "3980000333858" to be in freezer "PacBio sequencing freezer"
    Given I am on the show page for pipeline "PacBio Sequencing"
    When I check "Select Request Group 0"
    And I press the first "Submit"
    When I follow "Binding Kit Box Barcode"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I select "30" from "Movie length for 333"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
    When I drag the library tube to well "A1"
    And I press "Next step"
    Then I should see "Validate Sample Sheet"
    And I should see "Download Sample Sheet"
    And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name   | CP Parameters                                                                                                          |
      | A01      | DN1234567T-A1 | AcquisitionTime=30\|InsertSize=2000\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 |
    When I press "Release this batch"
    Then I should see "Batch released!"
    When I follow "Print plate labels"
    Then I should see "99999"
    When Pmb has the required label templates
    And Pmb is up and running
    And I press "Print labels"
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print out the library tube barcodes
    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    Given sample tube "111" is part of study "Test study"
    Given I have a PacBio Library Prep batch
    When I follow "Print labels"
    When I select "xyz" from "Print to"
    When Pmb has the required label templates
    And Pmb is up and running
    And I press "Print labels"
    Then I should see "Your 2 label(s) have been sent to printer xyz"
