@pacbio @submission @barcode-service @sample_validation_service @pacbio_sequencing
Feature: Push samples through the PacBio pipeline for sequencing

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    Given I am on the show page for study "Test study"

    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    And the plate barcode webservice returns "99999"
    Given the sample validation webservice returns "true"
      And the reference genome "Mouse" exists
    Given the study "Test study" has a reference genome of "Mouse"

  Scenario: No kit number entered for sequencing step
    Given I have a PacBio sequencing batch
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with ""
    And I press "Next step"
    Then I should see "Please enter a Kit Barcode"

  Scenario: Add invalid movie lengths
    Given I have a fast PacBio sequencing batch
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I fill in "Movie length for 333" with ""
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "abc"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "0"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "-1"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "1,,2"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with ",2,"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "1,20m,5"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "1,0,1"
    And I press "Next step"
    Then I should see "Invalid movie length"
    When I fill in "Movie length for 333" with "1,-1"
    And I press "Next step"
    Then I should see "Invalid movie length"


  Scenario Outline: Add Valid movie lengths
    Given I have a fast PacBio sequencing batch
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I fill in "Movie length for 333" with "<movie_length_1>"
    When I fill in "Movie length for 444" with "<movie_length_2>"
    And I press "Next step"
    Then I should not see "Invalid movie length"
    Examples:
      | movie_length_1 | movie_length_2    |
      | 1              | 1,2,3,4,5,6,7,8,9 |
      | 5,1,7          | 5,    1 , 7       |

  Scenario: Default layout of tubes on a plate
    Given I have a PacBio sequencing batch
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I fill in "Movie length for 333" with "12"
    And I fill in "Movie length for 444" with "23"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
    And the plate layout should look like:
      | 1        | 2        | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      | Tube 333 | Tube 444 |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
   And I press "Next step"
   And I press "Next step"

   Given the UUID for the last batch is "00000000-1111-2222-3333-444444444445"
   And the UUID for well "A1" on plate "99999" is "00000000-1111-2222-3333-444444444441"
   And the UUID for well "A2" on plate "99999" is "00000000-1111-2222-3333-444444444442"
   And the UUID for Library "333" is "00000000-1111-2222-3333-444444444443"
   And the UUID for Library "444" is "00000000-1111-2222-3333-444444444444"
   And all requests have sequential UUIDs based on "00000000-1111-2222-3333"

   Then the PacBio manifest for the last batch should look like:
     | Well No. | Sample Name | DNA Template Prep Kit Box Barcode | Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol   | CP Parameters                                             | Basecaller | User Field 1                         | User Field 2                         | User Field 3                         | User Field 4 | User Field 5                         |
     | A01      | Sample_111  | 999                               | 777                     | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=12\|InsertSize=250\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444441 | 00000000-1111-2222-3333-444444444443 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000003 |
     | A02      | Sample_222  | 999                               | 777                     | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=23\|InsertSize=250\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444442 | 00000000-1111-2222-3333-444444444444 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000004 |
   When I press "Release this batch"
   Then I should see "Batch released!"

   Scenario: Display samplesheet
     Given I have a PacBio sequencing batch
     When I follow "Start batch"
     When I fill in "Binding Kit Box Barcode" with "777"
     And I press "Next step"
     When I fill in "Movie length for 333" with "12"
     And I fill in "Movie length for 444" with "23"
     And I press "Next step"
     And I press "Next step"
     Then I should see "Layout tubes on a plate"
     And the plate layout should look like:
       | 1        | 2        | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
       | Tube 333 | Tube 444 |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
       |          |          |   |   |   |   |   |   |   |    |    |    |
     When I press "Next step"

     Given the UUID for the last batch is "00000000-1111-2222-3333-444444444445"
     And the UUID for well "A1" on plate "99999" is "00000000-1111-2222-3333-444444444441"
     And the UUID for well "A2" on plate "99999" is "00000000-1111-2222-3333-444444444442"
     And the UUID for Library "333" is "00000000-1111-2222-3333-444444444443"
     And the UUID for Library "444" is "00000000-1111-2222-3333-444444444444"
     And all requests have sequential UUIDs based on "00000000-1111-2222-3333"

     Then I should see "Validate Sample Sheet"
     And I should see "Download Sample Sheet"
     When I follow "Download Sample Sheet"
     Then the PacBio manifest should be:
       | Well No. | Sample Name | DNA Template Prep Kit Box Barcode |  Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol   | CP Parameters                                             | Basecaller | User Field 1                         | User Field 2                         | User Field 3                         | User Field 4 | User Field 5                         |
       | A01      | Sample_111  | 999                               | 777                      | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=12\|InsertSize=250\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444441 | 00000000-1111-2222-3333-444444444443 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000003 |
       | A02      | Sample_222  | 999                               | 777                      | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=23\|InsertSize=250\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444442 | 00000000-1111-2222-3333-444444444444 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000004 |

  Scenario: Alter tube layout on the plate
    Given I have a PacBio sequencing batch
    When I follow "Start batch"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I fill in "Movie length for 333" with "12"
    And I fill in "Movie length for 444" with "23"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
    And the plate layout should look like:
      | 1        | 2        | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      | Tube 333 | Tube 444 |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
      |          |          |   |   |   |   |   |   |   |    |    |    |
    When I select "" from "Well A1"
    And I select "" from "Well A2"
    And I select "Tube 333" from "Well C2"
    And I select "Tube 444" from "Well A12"
    And I press "Next step"
    And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name | DNA Template Prep Kit Box Barcode |  Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol         | CP Parameters                                             | Basecaller     |
      | C02      | Sample_111  | 999                               |  777                     | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=12\|InsertSize=250\|NumberOfCollections=1 | Default        |
      | A12      | Sample_222  | 999                               |  777                     | UsedControl=true       | Standard Seq 2-Set v1 | AcquisitionTime=23\|InsertSize=250\|NumberOfCollections=1 | Default        |
    When I press "Release this batch"
    Then I should see "Batch released!"

