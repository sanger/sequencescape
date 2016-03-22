@nano_grams @cherrypicking_for_pulldown @cherrypicking @barcode-service @pulldown @tecan
Feature: Pick a ng quantity using the Tecan robot

  Background:
    Given I am an "manager" user logged in as "john"
    And a robot exists

  @gwl
  Scenario: Create a Tecan file with the correct volumes to pick
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B1            | 100                    | 20              |
      | B2            | 120                    | 10              |
      | B3            | 140                    | 20              |
      | B4            | 160                    | 20              |
      | B5            | 0                      | 80              |
      | B6            | 0                      | 20              |
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

    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
    And I have a "Cherrypicking for Pulldown" submission with plate "333"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    And the last batch is sorted in row order
    And I fill in the following:
      | Minimum Volume    | 10   |
      | Maximum Volume    | 50   |
      | Quantity to pick  | 1000 |
    And I select "Pulldown" from "Plate Purpose"
    And "Pulldown" plate purpose picks with "Cherrypick::Strategy::Filter::InRowOrder"
    When I choose "Pick by ng"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
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
    A;1220000222748;;ABgene 0765;34;;50.0
    D;1220099999705;;ABgene 0800;5;;50.0
    W;
    A;1220000222748;;ABgene 0765;42;;20.0
    D;1220099999705;;ABgene 0800;6;;20.0
    W;
    A;1220000333802;;ABgene 0765;19;;30.0
    D;1220099999705;;ABgene 0800;7;;30.0
    W;
    A;1220000333802;;ABgene 0765;27;;1.0
    D;1220099999705;;ABgene 0800;8;;1.0
    W;
    A;1220000333802;;ABgene 0765;35;;1.1
    D;1220099999705;;ABgene 0800;9;;1.1
    W;
    A;1220000333802;;ABgene 0765;43;;1.3
    D;1220099999705;;ABgene 0800;10;;1.3
    W;
    A;1220000333802;;ABgene 0765;51;;1.4
    D;1220099999705;;ABgene 0800;11;;1.4
    W;
    A;1220000333802;;ABgene 0765;59;;1.7
    D;1220099999705;;ABgene 0800;12;;1.7
    W;
    A;1220000333802;;ABgene 0765;4;;10.0
    D;1220099999705;;ABgene 0800;13;;10.0
    W;
    A;1220000333802;;ABgene 0765;12;;10.0
    D;1220099999705;;ABgene 0800;14;;10.0
    W;
    A;1220000333802;;ABgene 0765;20;;15.0
    D;1220099999705;;ABgene 0800;15;;15.0
    W;
    A;1220000333802;;ABgene 0765;28;;20.0
    D;1220099999705;;ABgene 0800;16;;20.0
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
    A;BUFF;;96-TROUGH;8;;9.0
    D;1220099999705;;ABgene 0800;8;;9.0
    W;
    A;BUFF;;96-TROUGH;9;;8.9
    D;1220099999705;;ABgene 0800;9;;8.9
    W;
    A;BUFF;;96-TROUGH;10;;8.8
    D;1220099999705;;ABgene 0800;10;;8.8
    W;
    A;BUFF;;96-TROUGH;11;;8.6
    D;1220099999705;;ABgene 0800;11;;8.6
    W;
    A;BUFF;;96-TROUGH;12;;8.3
    D;1220099999705;;ABgene 0800;12;;8.3
    W;
    C;
    C; SCRC1 = 1220000222748
    C; SCRC2 = 1220000333802
    C;
    C; DEST1 = 1220099999705
    """
    When I follow "Print worksheet for Plate 99999"
    Then I should see the cherrypick worksheet table:
     | 1                               | 2                               |
     | B1        222        v10.0 b0.0 | C5        333        v1.1  b8.9 |
     | B2        222        v8.3  b1.7 | C6        333        v1.3  b8.8 |
     | B3        222        v7.1  b2.9 | C7        333        v1.4  b8.6 |
     | B4        222        v6.3  b3.8 | C8        333        v1.7  b8.3 |
     | B5        222        v50.0 b0.0 | D1        333        v10.0 b0.0 |
     | B6        222        v20.0 b0.0 | D2        333        v10.0 b0.0 |
     | C3        333        v30.0 b0.0 | D3        333        v15.0 b0.0 |
     | C4        333        v1.0  b9.0 | D4        333        v20.0 b0.0 |
     | 1                               | 2                               |

  Scenario: Try to cherrypick where 1 well has no concentration
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B2            |                        | 10              |
    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    And I check "Select DN222J for batch"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    When I choose "Pick by ng"
    And I fill in the following:
      | Minimum Volume    | 10   |
      | Maximum Volume    | 50   |
      | Quantity to pick  | 1000 |
    And I press "Next step"
    Then I should see "Missing measured concentration for well DN222J:B2"

   Scenario: Try to cherrypick where 1 well has no volume
     Given a plate barcode webservice is available and returns "99999"
     Given I have a plate "222" with the following wells:
       | well_location | measured_concentration | measured_volume |
       | B2            | 120                    |                 |
     Given I have a "Cherrypicking for Pulldown" submission with plate "222"
     Given I am on the show page for pipeline "Cherrypicking for Pulldown"
     And I check "Select DN222J for batch"
     And I select "Create Batch" from the first "Action to perform"
     And I press the first "Submit"
     When I follow "Cherrypick Group By Submission"
     When I choose "Pick by ng"
     And I fill in the following:
       | Minimum Volume    | 10   |
       | Maximum Volume    | 50   |
       | Quantity to pick  | 1000 |
     And I press "Next step"
    Then I should see "Missing measured volume for well DN222J:B2"

   Scenario Outline: Invalid picking options
     Given I have a plate "222" with the following wells:
       | well_location | measured_concentration | measured_volume |
       | B1            | 100                    | 20              |
     Given I have a "Cherrypicking for Pulldown" submission with plate "222"
     Given I am on the show page for pipeline "Cherrypicking for Pulldown"
     And I check "Select DN222J for batch"
     And I select "Create Batch" from the first "Action to perform"
     And I press the first "Submit"
     When I follow "Cherrypick Group By Submission"
     And I fill in the following:
       | Minimum Volume    | <minimum_volume>   |
       | Maximum Volume    | <maximum_volume>   |
       | Quantity to pick  | <target_ng>        |
     When I choose "Pick by ng"
     And I press "Next step"
     Then I should see "Invalid values typed in"
     Examples:
       | minimum_volume | maximum_volume | target_ng |
       |                | 20             | 1000      |
       | 10             |                | 1000      |
       | 10             | 20             |           |
       | abc            | 20             | 1000      |
       | 10             | 0.0            | 1.0       |
       | 10             | 5              | 1000      |


