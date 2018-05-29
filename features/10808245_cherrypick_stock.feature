@micro_litres @cherrypicking @barcode-service @tecan
Feature: Pick by micro litre (stock transfer) using the Tecan robot

  Background:
    Given I am an "manager" user logged in as "john"
    And a robot exists

  @cherrypicking @javascript @gwl
  Scenario Outline: Stock transfer by micro litres in Cherrypicking pipeline
    Given I have a project called "Test project"
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
     And I press the first "Submit"
     And I follow "Select Plate Template"
     And I select "testtemplate" from "Plate Template"
   	 And I select "Infinium 670k" from "Output plate purpose"

    When I choose "Pick by µl"
     And I fill in the following:
        | micro_litre_volume_required |  <volume>  |

   	 And I press "Next step"
   	 And I press "Next step"
   	 And I press "Release this batch"
   	Given the last batch has a barcode of "550000555760"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;1220000001831;;ABgene 0765;1;;<volume>.0
    D;1220099999705;;ABgene 0800;1;;<volume>.0
    W;
    A;1220000001831;;ABgene 0765;9;;<volume>.0
    D;1220099999705;;ABgene 0800;2;;<volume>.0
    W;
    A;1220000010734;;ABgene 0765;1;;<volume>.0
    D;1220099999705;;ABgene 0800;3;;<volume>.0
    W;
    A;1220000010734;;ABgene 0765;9;;<volume>.0
    D;1220099999705;;ABgene 0800;4;;<volume>.0
    W;
    A;1220000005877;;ABgene 0765;1;;<volume>.0
    D;1220099999705;;ABgene 0800;5;;<volume>.0
    W;
    A;1220000005877;;ABgene 0765;9;;<volume>.0
    D;1220099999705;;ABgene 0800;6;;<volume>.0
    W;
    C;
    C; SCRC1 = 1220000001831
    C; SCRC2 = 1220000010734
    C; SCRC3 = 1220000005877
    C;
    C; DEST1 = 1220099999705
    """
    When I follow "Print worksheet for Plate DN99999F"
    Then I should see the cherrypick worksheet table:
      | 1                                   |
      | A1        1        v<volume>.0 b0.0 |
      | A2        1        v<volume>.0 b0.0 |
      | A1        10       v<volume>.0 b0.0 |
      | A2        10       v<volume>.0 b0.0 |
      | A1        5        v<volume>.0 b0.0 |
      | A2        5        v<volume>.0 b0.0 |
      |                                     |
      |                                     |
      | 1                                   |
    Examples:
      | volume |
      | 13     |
      | 65     |
