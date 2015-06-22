@pacbio @submission @barcode-service @sample_validation_service @pacbio_sequencing
Feature: Push samples through the PacBio pipeline for sequencing

  Background:
    Given I am a "manager" user logged in as "user"
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    Given I am on the show page for study "Test study"

    Given I have a sample tube "111" in study "Test study" in asset group "Test study group"
    And the plate barcode webservice returns "99997..99999"
    Given the sample validation webservice returns "true"
      And the reference genome "Mouse" exists
    Given the study "Test study" has a reference genome of "Mouse"

  Scenario: No kit number entered for sequencing step
    Given I have a PacBio sequencing batch
    When I follow "Binding Kit Box Barcode"
    When I fill in "Binding Kit Box Barcode" with ""
    And I press "Next step"
    Then I should see "Please enter a Kit Barcode"


  Scenario Outline: Add Valid movie lengths
    Given I have a fast PacBio sequencing batch
    When I follow "Binding Kit Box Barcode"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I select "<movie_length_1>" from "Movie length for 333"
    When I select "<movie_length_2>" from "Movie length for 444"
    And I press "Next step"
    Then I should not see "Invalid movie length"
    Examples:
      | movie_length_1  | movie_length_2    |
      | 30              | 30                |
      | 60              | 30                |

  Scenario: Default layout of tubes on a plate
    Given I have a PacBio sequencing batch
    When I follow "Binding Kit Box Barcode"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I select "30" from "Movie length for 333"
    And I select "60" from "Movie length for 444"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
    And I fill in the field for "DN1234567T-A1" with "A1"
    And I fill in the field for "DN1234567T-B1" with "B1"
   And I press "Next step"
   And I press "Next step"

   Given the UUID for the last batch is "00000000-1111-2222-3333-444444444445"
   And the UUID for well "A1" on plate "99999" is "00000000-1111-2222-3333-444444444441"
   And the UUID for well "B1" on plate "99999" is "00000000-1111-2222-3333-444444444442"
   And the UUID for Library "333" is "00000000-1111-2222-3333-444444444443"
   And the UUID for Library "444" is "00000000-1111-2222-3333-444444444444"
   And all requests have sequential UUIDs based on "00000000-1111-2222-3333"

   Then the PacBio manifest for the last batch should look like:
     | Well No. | Sample Name | DNA Template Prep Kit Box Barcode | Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol   | CP Parameters                                             | Basecaller | User Field 1                         | User Field 2                         | User Field 3                         | User Field 4 | User Field 5                         |
     | A01      | DN1234567T-A1  | 999                               | 777                     |                        | Standard Seq v3 | AcquisitionTime=30\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444441 | 00000000-1111-2222-3333-444444444443 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000003 |
     | B01      | DN1234567T-B1  | 999                               | 777                     |                        | Standard Seq v3 | AcquisitionTime=60\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    | 00000000-1111-2222-3333-444444444442 | 00000000-1111-2222-3333-444444444444 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000004 |
   When I press "Release this batch"
   Then I should see "Batch released!"

   Scenario: Display samplesheet
     Given I have a PacBio sequencing batch
     When I follow "Binding Kit Box Barcode"
     When I fill in "Binding Kit Box Barcode" with "777"
     And I press "Next step"
     When I select "30" from "Movie length for 333"
     And I select "60" from "Movie length for 444"
     And I press "Next step"
     And I press "Next step"
     Then I should see "Layout tubes on a plate"
     And I fill in the field for "DN1234567T-A1" with "A1"
     And I fill in the field for "DN1234567T-B1" with "B1"
     When I press "Next step"

     Given the UUID for the last batch is "00000000-1111-2222-3333-444444444445"
     And the UUID for well "A1" on plate "99999" is "00000000-1111-2222-3333-444444444441"
     And the UUID for well "B1" on plate "99999" is "00000000-1111-2222-3333-444444444442"
     And the UUID for Library "333" is "00000000-1111-2222-3333-444444444443"
     And the UUID for Library "444" is "00000000-1111-2222-3333-444444444444"
     And all requests have sequential UUIDs based on "00000000-1111-2222-3333"

     Then I should see "Validate Sample Sheet"
     And I should see "Download Sample Sheet"
     When I follow "Download Sample Sheet"
     Then the PacBio manifest should be:
       | Well No. | Sample Name | DNA Template Prep Kit Box Barcode | Prep Kit Parameters | Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol   | CP Parameters                                                                                                         | Basecaller | Basecaller Parameters | Secondary Analysis Protocol | Secondary Analysis Parameters | Sample Comments | User Field 1                         | User Field 2                         | User Field 3                         | User Field 4 | User Field 5                         | User Field 6 | Results Data Output Path |
       | A01      | DN1234567T-A1  | 999                               |                     | 777                     |                        | Standard Seq v3 | AcquisitionTime=30\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    |                       |                             |                               |                 | 00000000-1111-2222-3333-444444444441 | 00000000-1111-2222-3333-444444444443 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000003 |              |                          |
       | B01      | DN1234567T-B1  | 999                               |                     | 777                     |                        | Standard Seq v3 | AcquisitionTime=60\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    |                       |                             |                               |                 | 00000000-1111-2222-3333-444444444442 | 00000000-1111-2222-3333-444444444444 | 00000000-1111-2222-3333-444444444445 | 99999        | 00000000-1111-2222-3333-000000000004 |              |                          |


  Scenario: Alter tube layout on the plate (And flip the order as well!)
    Given I have a PacBio sequencing batch
    When I follow "Binding Kit Box Barcode"
    When I fill in "Binding Kit Box Barcode" with "777"
    And I press "Next step"
    When I select "30" from "Movie length for 333"
    And I select "60" from "Movie length for 444"
    And I press "Next step"
    And I press "Next step"
    Then I should see "Layout tubes on a plate"
     And I fill in the field for "DN1234567T-A1" with "C3"
     And I fill in the field for "DN1234567T-B1" with "C2"

    And I press "Next step"
    And I press "Next step"
    Then the PacBio manifest for the last batch should look like:
      | Well No. | Sample Name | DNA Template Prep Kit Box Barcode | Prep Kit Parameters | Binding Kit Box Barcode | Binding Kit Parameters | Collection Protocol   | CP Parameters                                                                                                         | Basecaller | Basecaller Parameters | Secondary Analysis Protocol | Secondary Analysis Parameters | Sample Comments |
      | C02      | DN1234567T-B1  | 999                               |                     | 777                     |                        | Standard Seq v3 | AcquisitionTime=60\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    |                       |                             |                               |                 |
      | C03      | DN1234567T-A1  | 999                               |                     | 777                     |                        | Standard Seq v3 | AcquisitionTime=30\|InsertSize=500\|StageHS=True\|SizeSelectionEnabled=False\|Use2ndLook=False\|NumberOfCollections=1 | Default    |                       |                             |                               |                 |

    When I press "Release this batch"
    Then I should see "Batch released!"

