@micro_litres @cherrypicking @barcode-service
Feature: Pick by micro litre (stock transfer) using the Tecan robot

  Background:
    Given I am an "manager" user logged in as "john"

  @gwl @cherrypicking_for_pulldown @pulldown
  Scenario Outline: Create a Tecan file with the correct volumes to pick
    Given a plate barcode webservice is available and returns "99999"
    And I have a plate "222" with the following wells:
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
     And I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN222J for batch"
     And I check "Select DN333P for batch"
     And I press "Submit"
     And I follow "Start batch"
     And I choose "Pick by µl"
     And I fill in the following:
        | Volume  | <volume>   |
     And I select "Pulldown Aliquot" from "Plate Purpose"
     And I press "Next step"
     And I press "Release this batch"
    Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;SCRC1;;ABgene_0765;2;;<volume>.0
    D;DEST1;;ABgene_0800;1;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;10;;<volume>.0
    D;DEST1;;ABgene_0800;2;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;18;;<volume>.0
    D;DEST1;;ABgene_0800;3;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;26;;<volume>.0
    D;DEST1;;ABgene_0800;4;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;34;;<volume>.0
    D;DEST1;;ABgene_0800;5;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;42;;<volume>.0
    D;DEST1;;ABgene_0800;6;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;19;;<volume>.0
    D;DEST1;;ABgene_0800;7;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;27;;<volume>.0
    D;DEST1;;ABgene_0800;8;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;35;;<volume>.0
    D;DEST1;;ABgene_0800;9;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;43;;<volume>.0
    D;DEST1;;ABgene_0800;10;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;51;;<volume>.0
    D;DEST1;;ABgene_0800;11;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;59;;<volume>.0
    D;DEST1;;ABgene_0800;12;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;4;;<volume>.0
    D;DEST1;;ABgene_0800;13;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;12;;<volume>.0
    D;DEST1;;ABgene_0800;14;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;20;;<volume>.0
    D;DEST1;;ABgene_0800;15;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;28;;<volume>.0
    D;DEST1;;ABgene_0800;16;;<volume>.0
    W;
    C;
    C; SCRC1 = 222
    C; SCRC2 = 333
    C;
    C; DEST1 = 99999
    """
    When I follow "Print worksheet for Plate 99999"
    Then I should see the cherrypick worksheet table:
      | 1                                 | 2                                 |
      | B1        222        v<volume> b0 | C5        333        v<volume> b0 |
      | B2        222        v<volume> b0 | C6        333        v<volume> b0 |
      | B3        222        v<volume> b0 | C7        333        v<volume> b0 |
      | B4        222        v<volume> b0 | C8        333        v<volume> b0 |
      | B5        222        v<volume> b0 | D1        333        v<volume> b0 |
      | B6        222        v<volume> b0 | D2        333        v<volume> b0 |
      | C3        333        v<volume> b0 | D3        333        v<volume> b0 |
      | C4        333        v<volume> b0 | D4        333        v<volume> b0 |
      | 1                                 | 2                                 |
    Examples:
      | volume |
      | 13     |
      | 65     |


  @cherrypicking_for_pulldown @pulldown
  Scenario: Invalid picking options when picking volume in micro litres
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B1            |     10                 |   10            |
    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
     And I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN222J for batch"
     And I press "Submit"
     And I follow "Start batch"

    When I choose "Pick by µl"
     And I fill in the following:
        | Volume  |     |
     And I press "Next step"
    Then I should see "Invalid values typed in"

    When I choose "Pick by µl"
     And I fill in the following:
        | Volume  |  abc  |
     And I press "Next step"
    Then I should see "Invalid values typed in"

    When I choose "Pick by µl"
     And I fill in the following:
        | Volume  |  0  |
     And I press "Next step"
    Then I should see "Invalid values typed in"

    When I choose "Pick by µl"
     And I fill in the following:
        | Volume  |  -1  |
     And I press "Next step"
    Then I should see "Invalid values typed in"
    
  @cherrypicking @javascript @gwl
  Scenario Outline: Stock transfer by micro litres in Cherrypicking pipeline
    Given I have a project called "Test project"
     And project "Test project" has enough quotas
     And I have an active study called "Test study"
     And I have a plate "1" in study "Test study" with 2 samples in asset group "Plate asset group"
     And I have a plate "10" in study "Test study" with 2 samples in asset group "Plate asset group"
     And I have a plate "5" in study "Test study" with 2 samples in asset group "Plate asset group"
     And I have a Cherrypicking submission for asset group "Plate asset group"
     And I am on the show page for pipeline "Cherrypick"
     And a plate barcode webservice is available and returns "99999"
     And a plate template exists
     And a robot exists with barcode "444"
    When I check "Select DN1S for batch"
     And I check "Select DN10I for batch"
     And I check "Select DN5W for batch"
     And I press "Submit"
    	And I follow "Start batch"
    	And I select "testtemplate" from "Plate Template"
    	
    When I choose "Pick by µl"
     And I fill in the following:
        | Volume  |  <volume>  |
      
     And I press "Next step"
   	 And I press "Submit"
   	 And I select "Infinium 670k" from "Plate Purpose"
   	 And I press "Next step"
   	 And I select "Genotyping freezer" from "Location"
   	 And I press "Next step"
   	 And I press "Release this batch"
   	Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;SCRC1;;ABgene_0765;1;;<volume>.0
    D;DEST1;;ABgene_0800;1;;<volume>.0
    W;
    A;SCRC1;;ABgene_0765;9;;<volume>.0
    D;DEST1;;ABgene_0800;2;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;1;;<volume>.0
    D;DEST1;;ABgene_0800;3;;<volume>.0
    W;
    A;SCRC2;;ABgene_0765;9;;<volume>.0
    D;DEST1;;ABgene_0800;4;;<volume>.0
    W;
    A;SCRC3;;ABgene_0765;1;;<volume>.0
    D;DEST1;;ABgene_0800;5;;<volume>.0
    W;
    A;SCRC3;;ABgene_0765;9;;<volume>.0
    D;DEST1;;ABgene_0800;6;;<volume>.0
    W;
    C;
    C; SCRC1 = 1
    C; SCRC2 = 10
    C; SCRC3 = 5
    C;
    C; DEST1 = 99999
    """
    When I follow "Print worksheet for Plate 99999"
    Then I should see the cherrypick worksheet table:
      | 1                                 |
      | A1        1        v<volume> b0   |
      | A2        1        v<volume> b0   |
      | A1        10        v<volume> b0  |
      | A2        10        v<volume> b0  |
      | A1        5        v<volume> b0   |
      | A2        5        v<volume> b0   |
      |                                   |
      |                                   |
      | 1                                 |
    Examples:
      | volume |
      | 13     |
      | 65     |
