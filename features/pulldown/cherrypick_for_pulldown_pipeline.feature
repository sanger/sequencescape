@cherrypicking_for_pulldown @cherrypicking @barcode-service @pulldown @tecan
Feature: Cherrypicking for Pulldown pipeline

  Background:
    Given I am a "administrator" user logged in as "user"

  Scenario: All parts of a submission across multiple plates must be in batch
    Given I have a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission with 2 plates
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN222J for batch"
    And I press "Submit"
    Then I should see "All plates in a submission must be selected"
    When I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I press "Submit"
    Then I should see "This batch belongs to pipeline: Cherrypicking for Pulldown"

  Scenario: Dont allow more than 96 wells in a batch
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    And I have an active study called "Study A"

    Given the CherrypickForPulldownPipeline pipeline has a max batch size of 2
    Given plate "1234567" with 2 samples in study "Test study" has a "Cherrypicking for Pulldown" submission for cherrypicking
    Given plate "222" with 1 samples in study "Study A" has a "Cherrypicking for Pulldown" submission for cherrypicking
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    Then I should see "This pipelines has a limit of 2 requests in a batch"
    Then I should see "There are 3 requests available."
    When I check "Select DN1234567T for batch"
    And I check "Select DN222J for batch"
    And I press "Submit"
    Then I should see "Maximum batch size is 2"
    Then I should see "This pipelines has a limit of 2 requests in a batch"
    Then I should see "There are 3 requests available."

 Scenario: Cherrypick for pulldown from 2 submissions from different studies and view worksheet
   Given I have a project called "Test project"
   And project "Test project" has enough quotas
   Given I have an active study called "Test study"
   And I have an active study called "Study A"
   And the "96 Well Plate" barcode printer "xyz" exists

   Given plate "1234567" with 8 samples in study "Test study" has a "Cherrypicking for Pulldown" submission for cherrypicking
   Given plate "222" with 8 samples in study "Study A" has a "Cherrypicking for Pulldown" submission for cherrypicking
   Given plate "1234567" has nonzero concentration results
   Given plate "222" has nonzero concentration results

   Given I am on the show page for pipeline "Cherrypicking for Pulldown"
   When I check "Select DN1234567T for batch"
   And I check "Select DN222J for batch"
   And I press "Submit"
   Then I should see "This batch belongs to pipeline: Cherrypicking for Pulldown"
   And I should see "Cherrypick Group By Submission"
   Given a plate barcode webservice is available and returns "99999"
   When I follow "Start batch"
   When I fill in "Volume Required" with "13"
   And I fill in "Concentration Required" with "50"
   And I select "Pulldown" from "Plate Purpose"
   And I press "Next step"
   When I press "Release this batch"
   Then I should see "Batch released!"
   Given the last batch has a barcode of "550000555760"
   Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
   """
   C;
   A;1221234567841;;ABgene 0765;1;;13.0
   D;1220099999705;;ABgene 0800;1;;13.0
   W;
   A;1221234567841;;ABgene 0765;9;;13.0
   D;1220099999705;;ABgene 0800;2;;13.0
   W;
   A;1221234567841;;ABgene 0765;17;;9.0
   D;1220099999705;;ABgene 0800;3;;9.0
   W;
   A;1221234567841;;ABgene 0765;25;;6.0
   D;1220099999705;;ABgene 0800;4;;6.0
   W;
   A;1221234567841;;ABgene 0765;33;;5.0
   D;1220099999705;;ABgene 0800;5;;5.0
   W;
   A;1221234567841;;ABgene 0765;41;;4.0
   D;1220099999705;;ABgene 0800;6;;4.0
   W;
   A;1221234567841;;ABgene 0765;49;;3.0
   D;1220099999705;;ABgene 0800;7;;3.0
   W;
   A;1221234567841;;ABgene 0765;57;;3.0
   D;1220099999705;;ABgene 0800;8;;3.0
   W;
   A;1220000222748;;ABgene 0765;1;;13.0
   D;1220099999705;;ABgene 0800;9;;13.0
   W;
   A;1220000222748;;ABgene 0765;9;;13.0
   D;1220099999705;;ABgene 0800;10;;13.0
   W;
   A;1220000222748;;ABgene 0765;17;;9.0
   D;1220099999705;;ABgene 0800;11;;9.0
   W;
   A;1220000222748;;ABgene 0765;25;;6.0
   D;1220099999705;;ABgene 0800;12;;6.0
   W;
   A;1220000222748;;ABgene 0765;33;;5.0
   D;1220099999705;;ABgene 0800;13;;5.0
   W;
   A;1220000222748;;ABgene 0765;41;;4.0
   D;1220099999705;;ABgene 0800;14;;4.0
   W;
   A;1220000222748;;ABgene 0765;49;;3.0
   D;1220099999705;;ABgene 0800;15;;3.0
   W;
   A;1220000222748;;ABgene 0765;57;;3.0
   D;1220099999705;;ABgene 0800;16;;3.0
   W;
   C;
   A;BUFF;;96-TROUGH;3;;4.0
   D;1220099999705;;ABgene 0800;3;;4.0
   W;
   A;BUFF;;96-TROUGH;4;;7.0
   D;1220099999705;;ABgene 0800;4;;7.0
   W;
   A;BUFF;;96-TROUGH;5;;8.0
   D;1220099999705;;ABgene 0800;5;;8.0
   W;
   A;BUFF;;96-TROUGH;6;;9.0
   D;1220099999705;;ABgene 0800;6;;9.0
   W;
   A;BUFF;;96-TROUGH;7;;10.0
   D;1220099999705;;ABgene 0800;7;;10.0
   W;
   A;BUFF;;96-TROUGH;8;;10.0
   D;1220099999705;;ABgene 0800;8;;10.0
   W;
   A;BUFF;;96-TROUGH;11;;4.0
   D;1220099999705;;ABgene 0800;11;;4.0
   W;
   A;BUFF;;96-TROUGH;12;;7.0
   D;1220099999705;;ABgene 0800;12;;7.0
   W;
   A;BUFF;;96-TROUGH;13;;8.0
   D;1220099999705;;ABgene 0800;13;;8.0
   W;
   A;BUFF;;96-TROUGH;14;;9.0
   D;1220099999705;;ABgene 0800;14;;9.0
   W;
   A;BUFF;;96-TROUGH;15;;10.0
   D;1220099999705;;ABgene 0800;15;;10.0
   W;
   A;BUFF;;96-TROUGH;16;;10.0
   D;1220099999705;;ABgene 0800;16;;10.0
   W;
   C;
   C; SCRC1 = 1221234567841
   C; SCRC2 = 1220000222748
   C;
   C; DEST1 = 1220099999705
   """
   When I follow "Print worksheet for Plate 99999"
   Then I should see the cherrypick worksheet table:
    | 1                                | 2                           |
    | A1        1234567        v13 b0  | A1        222        v13 b0 |
    | A2        1234567        v13 b0  | A2        222        v13 b0 |
    | A3        1234567        v9 b4   | A3        222        v9 b4  |
    | A4        1234567        v6 b7   | A4        222        v6 b7  |
    | A5        1234567        v5 b8   | A5        222        v5 b8  |
    | A6        1234567        v4 b9   | A6        222        v4 b9  |
    | A7        1234567        v3 b10  | A7        222        v3 b10 |
    | A8        1234567        v3 b10  | A8        222        v3 b10 |
    | 1                                | 2                           |


