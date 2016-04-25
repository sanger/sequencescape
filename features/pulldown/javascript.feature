@pulldown @javascript @barcode-service @cherrypicking_for_pulldown @pulldown_javascript @tecan
Feature: Print barcodes for the cherrypicking for pulldown and pulldown multiplex pipelines

  Background:
    Given I am a "administrator" user logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given a robot exists


  Scenario: Create a Tecan file with correct volumes to pick via the original Cherrypick interface
    Given a plate template exists
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B1            | 100                    | 20              |
      | B2            | 120                    | 10              |
      | B3            | 140                    | 20              |
      | B4            | 160                    | 20              |
      | B5            | 180                    | 20              |
      | B6            | 200                    | 20              |
    And I have a plate "333" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | C3            | 10                     | 30              |
      | C4            | 1000                   | 10              |
      | C5            | 900                    | 10              |
      | C6            | 800                    | 10              |
      | C7            | 700                    | 10              |
      | C8            | 600                    | 10              |
      | D1            | 90                     | 10              |
      | D2            | 50                     | 10              |
      | D3            | 40                     | 15              |
      | D4            | 50                     | 20              |
    Given I have a cherrypicking submission for plate "222"
    And I have a cherrypicking submission for plate "333"
    Given I am on the show page for pipeline "Cherrypick"
    When I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I press the first "Submit"
    When I follow "Select Plate Template"
    And I fill in the following:
      | Minimum Volume    | 10   |
      | Maximum Volume    | 50   |
      | Quantity to pick  | 1000 |
    And I choose "Pick by ng"
    And I press "Next step"
    When I press "Next step"
    Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;1220000222748;;ABgene 0765;2;;10.0
    D;1220099999705;;ABgene 0800;1;;10.0
    W;
    A;1220000222748;;ABgene 0765;10;;8.3
    D;1220099999705;;ABgene 0800;2;;8.3
    W;
    A;1220000222748;;ABgene 0765;18;;7.1
    D;1220099999705;;ABgene 0800;3;;7.1
    W;
    A;1220000222748;;ABgene 0765;26;;6.3
    D;1220099999705;;ABgene 0800;4;;6.3
    W;
    A;1220000222748;;ABgene 0765;34;;5.6
    D;1220099999705;;ABgene 0800;5;;5.6
    W;
    A;1220000222748;;ABgene 0765;42;;5.0
    D;1220099999705;;ABgene 0800;6;;5.0
    W;
    A;1220000333802;;ABgene 0765;4;;10.0
    D;1220099999705;;ABgene 0800;7;;10.0
    W;
    A;1220000333802;;ABgene 0765;12;;10.0
    D;1220099999705;;ABgene 0800;8;;10.0
    W;
    A;1220000333802;;ABgene 0765;19;;30.0
    D;1220099999705;;ABgene 0800;9;;30.0
    W;
    A;1220000333802;;ABgene 0765;20;;15.0
    D;1220099999705;;ABgene 0800;10;;15.0
    W;
    A;1220000333802;;ABgene 0765;27;;1.0
    D;1220099999705;;ABgene 0800;11;;1.0
    W;
    A;1220000333802;;ABgene 0765;28;;20.0
    D;1220099999705;;ABgene 0800;12;;20.0
    W;
    A;1220000333802;;ABgene 0765;35;;1.1
    D;1220099999705;;ABgene 0800;13;;1.1
    W;
    A;1220000333802;;ABgene 0765;43;;1.3
    D;1220099999705;;ABgene 0800;14;;1.3
    W;
    A;1220000333802;;ABgene 0765;51;;1.4
    D;1220099999705;;ABgene 0800;15;;1.4
    W;
    A;1220000333802;;ABgene 0765;59;;1.7
    D;1220099999705;;ABgene 0800;16;;1.7
    W;
    C;
    A;BUFF;;96-TROUGH;2;;1.7
    D;1220099999705;;ABgene 0800;2;;1.7
    W;
    A;BUFF;;96-TROUGH;3;;2.9
    D;1220099999705;;ABgene 0800;3;;2.9
    W;
    A;BUFF;;96-TROUGH;4;;3.8
    D;1220099999705;;ABgene 0800;4;;3.8
    W;
    A;BUFF;;96-TROUGH;5;;4.4
    D;1220099999705;;ABgene 0800;5;;4.4
    W;
    A;BUFF;;96-TROUGH;6;;5.0
    D;1220099999705;;ABgene 0800;6;;5.0
    W;
    A;BUFF;;96-TROUGH;11;;9.0
    D;1220099999705;;ABgene 0800;11;;9.0
    W;
    A;BUFF;;96-TROUGH;13;;8.9
    D;1220099999705;;ABgene 0800;13;;8.9
    W;
    A;BUFF;;96-TROUGH;14;;8.8
    D;1220099999705;;ABgene 0800;14;;8.8
    W;
    A;BUFF;;96-TROUGH;15;;8.6
    D;1220099999705;;ABgene 0800;15;;8.6
    W;
    A;BUFF;;96-TROUGH;16;;8.3
    D;1220099999705;;ABgene 0800;16;;8.3
    W;
    C;
    C; SCRC1 = 1220000222748
    C; SCRC2 = 1220000333802
    C;
    C; DEST1 = 1220099999705
    """

  Scenario: Count the number of selected requests in inbox
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    And I have an active study called "Study B"
    And I have an active study called "Study C"

    Given plate "1234567" with 2 samples in study "Test study" has a "Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing" submission
    Given plate "222" with 1 samples in study "Study B" has a "Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing" submission
    Given plate "333" with 3 samples in study "Study C" has a "Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing" submission
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    Then I should see "You have 2 requests selected"
    When I check "Select DN222J for batch"
    Then I should see "You have 3 requests selected"
    When I check "Select DN333P for batch"
    Then I should see "You have 6 requests selected"
    When I uncheck "Select DN222J for batch"
    Then I should see "You have 5 requests selected"
    When I uncheck "Select DN1234567T for batch"
    Then I should see "You have 3 requests selected"
    When I uncheck "Select DN333P for batch"
    Then I should see "You have no requests selected"

  @wip
  Scenario: Print tube barcodes for pulldown multiplexing
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    And I have an active study called "Study A"

    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Assign Tags"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    When I follow "Print labels"
    When I select "xyz" from "Print to"
    When I press "Print labels"
    Then I should see "Your labels have been printed to xyz."

  Scenario: Cherrypick for pulldown and print barcodes
    Given I have a project called "Test project"

    Given I have an active study called "Test study"

    Given a plate barcode webservice is available and returns "99999"
    Given plate "1234567" with 1 samples in study "Test study" has a "Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing" submission
    Given plate "1234567" has nonzero concentration results
    Given plate "1234567" has measured volume results
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    And I choose "Pick by ng/µl"
    And I select "WGS stock DNA" from "Plate Purpose"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    When I follow "Print plate labels"
    Then I should see "99999"
    When I select "xyz" from "Print to"
    When I press "Print labels"
    Then I should see "Your labels have been printed to xyz."
