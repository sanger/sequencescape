@nano_grams @cherrypicking @barcode-service  @javascript
Feature: Picking more than 13 minimum volume should render in tecan file

  Background: 
    Given I am an "manager" user logged in as "john"
    Given a plate template exists
    Given a robot exists

  @gwl
  Scenario: Create a Tecan file with the correct volumes to pick
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B1            | 10                     | 150              |
      | B2            | 12                     | 150              |
      | B3            | 14                     | 150              |
      | B4            | 16                     | 150              |
      | B5            | 18                     | 150              |
      | B6            | 40                     | 150              |
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

    Given I have a "Cherrypick" submission with plate "222"
    And I have a "Cherrypick" submission with plate "333"
    Given I am on the show page for pipeline "Cherrypick"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"
    When I follow "Start batch"
    When I select "testtemplate" from "Plate Template"
    And I choose "Pick by ng"
    And I fill in the following:
      | Minimum Volume    | 20   |
      | Maximum Volume    | 150   |
      | Quantity to pick  | 10000 |
    And I press "Next step"
		When I press "Submit"
		And I press "Next step"
		And I press "Next step"
    
    When I press "Release this batch"
    Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;SCRC1;;ABgene_0765;2;;150.0
    D;DEST1;;ABgene_0800;1;;150.0
    W;
    A;SCRC1;;ABgene_0765;10;;150.0
    D;DEST1;;ABgene_0800;2;;150.0
    W;
    A;SCRC1;;ABgene_0765;18;;150.0
    D;DEST1;;ABgene_0800;3;;150.0
    W;
    A;SCRC1;;ABgene_0765;26;;150.0
    D;DEST1;;ABgene_0800;4;;150.0
    W;
    A;SCRC1;;ABgene_0765;34;;150.0
    D;DEST1;;ABgene_0800;5;;150.0
    W;
    A;SCRC1;;ABgene_0765;42;;150.0
    D;DEST1;;ABgene_0800;6;;150.0
    W;
    A;SCRC2;;ABgene_0765;4;;10.0
    D;DEST1;;ABgene_0800;7;;10.0
    W;
    A;SCRC2;;ABgene_0765;12;;10.0
    D;DEST1;;ABgene_0800;8;;10.0
    W;
    A;SCRC2;;ABgene_0765;19;;30.0
    D;DEST1;;ABgene_0800;9;;30.0
    W;
    A;SCRC2;;ABgene_0765;20;;15.0
    D;DEST1;;ABgene_0800;10;;15.0
    W;
    A;SCRC2;;ABgene_0765;27;;10.0
    D;DEST1;;ABgene_0800;11;;10.0
    W;
    A;SCRC2;;ABgene_0765;28;;20.0
    D;DEST1;;ABgene_0800;12;;20.0
    W;
    A;SCRC2;;ABgene_0765;35;;10.0
    D;DEST1;;ABgene_0800;13;;10.0
    W;
    A;SCRC2;;ABgene_0765;43;;10.0
    D;DEST1;;ABgene_0800;14;;10.0
    W;
    A;SCRC2;;ABgene_0765;51;;10.0
    D;DEST1;;ABgene_0800;15;;10.0
    W;
    A;SCRC2;;ABgene_0765;59;;10.0
    D;DEST1;;ABgene_0800;16;;10.0
    W;
    C;
    A;BUFF;;96-TROUGH;7;;10.0
    D;DEST1;;ABgene_0800;7;;10.0
    W;
    A;BUFF;;96-TROUGH;8;;10.0
    D;DEST1;;ABgene_0800;8;;10.0
    W;
    A;BUFF;;96-TROUGH;10;;5.0
    D;DEST1;;ABgene_0800;10;;5.0
    W;
    A;BUFF;;96-TROUGH;11;;10.0
    D;DEST1;;ABgene_0800;11;;10.0
    W;
    A;BUFF;;96-TROUGH;13;;10.0
    D;DEST1;;ABgene_0800;13;;10.0
    W;
    A;BUFF;;96-TROUGH;14;;10.0
    D;DEST1;;ABgene_0800;14;;10.0
    W;
    A;BUFF;;96-TROUGH;15;;10.0
    D;DEST1;;ABgene_0800;15;;10.0
    W;
    A;BUFF;;96-TROUGH;16;;10.0
    D;DEST1;;ABgene_0800;16;;10.0
    W;
    C;
    C; SCRC1 = 222
    C; SCRC2 = 333
    C;
    C; DEST1 = 99999
    """
    When I follow "Print worksheet for Plate 99999"
    Then I should see the cherrypick worksheet table:
     | 1                            | 2                            | 
     | B1        222        v150 b0 | C3        333        v30 b0  |
     | B2        222        v150 b0 | D3        333        v15 b5  |
     | B3        222        v150 b0 | C4        333        v10 b10 |
     | B4        222        v150 b0 | D4        333        v20 b0  |
     | B5        222        v150 b0 | C5        333        v10 b10 |
     | B6        222        v150 b0 | C6        333        v10 b10 |
     | D1        333        v10 b10 | C7        333        v10 b10 |
     | D2        333        v10 b10 | C8        333        v10 b10 |
     | 1                            | 2                            |
