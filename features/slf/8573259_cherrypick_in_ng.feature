@nano_grams @cherrypicking_for_pulldown @cherrypicking @barcode-service @pulldown
Feature: Pick a ng quantity using the Tecan robot

  Background: 
    Given I am an "manager" user logged in as "john"

  @gwl
  Scenario: Create a Tecan file with the correct volumes to pick
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

    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
    And I have a "Cherrypicking for Pulldown" submission with plate "333"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"
    When I follow "Start batch"
    When I choose "Pick by ng"
    And I fill in the following:
      | Minimum Volume    | 10   |
      | Maximum Volume    | 50   |
      | Quantity to pick  | 1000 |
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;SCRC1;;ABgene_0765;2;;10.0
    D;DEST1;;ABgene_0800;1;;10.0
    W;
    A;SCRC1;;ABgene_0765;10;;9.0
    D;DEST1;;ABgene_0800;2;;9.0
    W;
    A;SCRC1;;ABgene_0765;18;;8.0
    D;DEST1;;ABgene_0800;3;;8.0
    W;
    A;SCRC1;;ABgene_0765;26;;7.0
    D;DEST1;;ABgene_0800;4;;7.0
    W;
    A;SCRC1;;ABgene_0765;34;;6.0
    D;DEST1;;ABgene_0800;5;;6.0
    W;
    A;SCRC1;;ABgene_0765;42;;5.0
    D;DEST1;;ABgene_0800;6;;5.0
    W;
    A;SCRC2;;ABgene_0765;19;;30.0
    D;DEST1;;ABgene_0800;7;;30.0
    W;
    A;SCRC2;;ABgene_0765;27;;1.0
    D;DEST1;;ABgene_0800;8;;1.0
    W;
    A;SCRC2;;ABgene_0765;35;;2.0
    D;DEST1;;ABgene_0800;9;;2.0
    W;
    A;SCRC2;;ABgene_0765;43;;2.0
    D;DEST1;;ABgene_0800;10;;2.0
    W;
    A;SCRC2;;ABgene_0765;51;;2.0
    D;DEST1;;ABgene_0800;11;;2.0
    W;
    A;SCRC2;;ABgene_0765;59;;2.0
    D;DEST1;;ABgene_0800;12;;2.0
    W;
    A;SCRC2;;ABgene_0765;4;;10.0
    D;DEST1;;ABgene_0800;13;;10.0
    W;
    A;SCRC2;;ABgene_0765;12;;10.0
    D;DEST1;;ABgene_0800;14;;10.0
    W;
    A;SCRC2;;ABgene_0765;20;;15.0
    D;DEST1;;ABgene_0800;15;;15.0
    W;
    A;SCRC2;;ABgene_0765;28;;20.0
    D;DEST1;;ABgene_0800;16;;20.0
    W;
    C;
    A;BUFF;;96-TROUGH;2;;1.0
    D;DEST1;;ABgene_0800;2;;1.0
    W;
    A;BUFF;;96-TROUGH;3;;2.0
    D;DEST1;;ABgene_0800;3;;2.0
    W;
    A;BUFF;;96-TROUGH;4;;3.0
    D;DEST1;;ABgene_0800;4;;3.0
    W;
    A;BUFF;;96-TROUGH;5;;4.0
    D;DEST1;;ABgene_0800;5;;4.0
    W;
    A;BUFF;;96-TROUGH;6;;5.0
    D;DEST1;;ABgene_0800;6;;5.0
    W;
    A;BUFF;;96-TROUGH;8;;9.0
    D;DEST1;;ABgene_0800;8;;9.0
    W;
    A;BUFF;;96-TROUGH;9;;8.0
    D;DEST1;;ABgene_0800;9;;8.0
    W;
    A;BUFF;;96-TROUGH;10;;8.0
    D;DEST1;;ABgene_0800;10;;8.0
    W;
    A;BUFF;;96-TROUGH;11;;8.0
    D;DEST1;;ABgene_0800;11;;8.0
    W;
    A;BUFF;;96-TROUGH;12;;8.0
    D;DEST1;;ABgene_0800;12;;8.0
    W;
    C;
    C; SCRC1 = 222
    C; SCRC2 = 333
    C;
    C; DEST1 = 99999
    """
    When I follow "Print worksheet for Plate 99999"
    Then I should see the cherrypick worksheet table:
     | 1                           | 2                           | 
     | B1        222        v10 b0 | C5        333        v2 b8  | 
     | B2        222        v9 b1  | C6        333        v2 b8  | 
     | B3        222        v8 b2  | C7        333        v2 b8  | 
     | B4        222        v7 b3  | C8        333        v2 b8  | 
     | B5        222        v6 b4  | D1        333        v10 b0 | 
     | B6        222        v5 b5  | D2        333        v10 b0 | 
     | C3        333        v30 b0 | D3        333        v15 b0 | 
     | C4        333        v1 b9  | D4        333        v20 b0 | 
     | 1                           | 2                           | 
     
  Scenario: Try to cherrypick where 1 well has no concentration
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B2            |                        | 10              |
    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    And I check "Select DN222J for batch"
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"
    When I follow "Start batch"
    When I choose "Pick by ng"
    And I fill in the following:
      | Minimum Volume    | 10   |
      | Maximum Volume    | 50   |
      | Quantity to pick  | 1000 |
    And I press "Next step"
    Then I should see "Missing measured concentration for Well"
  
   Scenario: Try to cherrypick where 1 well has no volume
     Given a plate barcode webservice is available and returns "99999"
     Given I have a plate "222" with the following wells:
       | well_location | measured_concentration | measured_volume |
       | B2            | 120                    |                 |
     Given I have a "Cherrypicking for Pulldown" submission with plate "222"
     Given I am on the show page for pipeline "Cherrypicking for Pulldown"
     And I check "Select DN222J for batch"
     And I select "Create Batch" from "Action to perform"
     And I press "Submit"
     When I follow "Start batch"
     When I choose "Pick by ng"
     And I fill in the following:
       | Minimum Volume    | 10   |
       | Maximum Volume    | 50   |
       | Quantity to pick  | 1000 |
     And I press "Next step"
     Then I should see "Missing measured volume for Well"
     
   Scenario Outline: Invalid picking options
     Given I have a plate "222" with the following wells:
       | well_location | measured_concentration | measured_volume |
       | B1            | 100                    | 20              |
     Given I have a "Cherrypicking for Pulldown" submission with plate "222"
     Given I am on the show page for pipeline "Cherrypicking for Pulldown"
     And I check "Select DN222J for batch"
     And I select "Create Batch" from "Action to perform"
     And I press "Submit"
     When I follow "Start batch"
     When I choose "Pick by ng"
     And I fill in the following:
       | Minimum Volume    | <minimum_volume>   |
       | Maximum Volume    | <maximum_volume>   |
       | Quantity to pick  | <target_ng> |
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

    
