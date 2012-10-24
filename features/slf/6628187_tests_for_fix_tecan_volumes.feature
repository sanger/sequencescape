@javascript @barcode-service @cherrypicking @gwl
Feature: The Tecan file has the wrong buffer volumes, defaulting to 13 total volume
  Scenario: volume of 65 is required
    Given I am a "administrator" user logged in as "user"
    Given I have a project called "Test project"
    And project "Test project" has enough quotas
    Given I have an active study called "Test study"
    Given I have a plate "1" in study "Test study" with 2 samples in asset group "Plate asset group"
    Given I have a plate "10" in study "Test study" with 2 samples in asset group "Plate asset group"
    Given I have a plate "5" in study "Test study" with 2 samples in asset group "Plate asset group"
    Given I have a Cherrypicking submission for asset group "Plate asset group"
    Given I am on the show page for pipeline "Cherrypick"
    When I check "Select DN1S for batch"
    When I check "Select DN10I for batch"
    When I check "Select DN5W for batch"
    And I select "Create Batch" from "action_on_requests"
    And I press "Submit"
    Given a plate barcode webservice is available and returns "99999"
    Given a plate template exists
    Given a robot exists with barcode "444"
    Given plate "1220000010734" has concentration and volume results
    Given plate "1220000001831" has concentration and volume results
    Given plate "1220000005877" has concentration and volume results
    When I follow "Start batch"
    When I select "testtemplate" from "Plate Template"

    When I fill in "Volume Required" with "65"
    When I press "Next step"
    When I press "Next step"
    When I select "Infinium 670k" from "Plate Purpose"
    And I press "Next step"
    When I select "Genotyping freezer" from "Location"
    And I press "Next step"
    When I press "Release this batch"
    Given the last batch has a barcode of "550000555760"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan Tecan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    1220099999705
    """
    And I press "Check"
    Then I should see "Scan robot beds and plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | 1220000001831 |
    | SCRC 2 | 1220000010734 |
    | SCRC 3 | 1220000005877 |
    | DEST 1 | 1220099999705 |

    When I fill in the following:
    | SCRC 1        | 4880000001780 |
    | 1220000001831 | 1220000001831 |
    | SCRC 2        | 4880000002794 |
    | 1220000005877 | 1220000005877 |
    | SCRC 3        | 4880000003807 |
    | 1220000010734 | 1220000010734 |
    | DEST 1        | 4880000020729 |
    | 1220099999705 | 1220099999705 |
    And I press "Verify"
    Then I should see "Download TECAN file"
    Then the downloaded tecan file for batch "550000555760" and plate "1220099999705" is
    """
    C;
    A;1220000001831;;ABgene 0765;1;;16.0
    D;1220099999705;;ABgene 0800;1;;16.0
    W;
    A;1220000001831;;ABgene 0765;9;;16.0
    D;1220099999705;;ABgene 0800;2;;16.0
    W;
    A;1220000010734;;ABgene 0765;1;;16.0
    D;1220099999705;;ABgene 0800;3;;16.0
    W;
    A;1220000010734;;ABgene 0765;9;;16.0
    D;1220099999705;;ABgene 0800;4;;16.0
    W;
    A;1220000005877;;ABgene 0765;1;;16.0
    D;1220099999705;;ABgene 0800;5;;16.0
    W;
    A;1220000005877;;ABgene 0765;9;;16.0
    D;1220099999705;;ABgene 0800;6;;16.0
    W;
    C;
    A;BUFF;;96-TROUGH;1;;49.0
    D;1220099999705;;ABgene 0800;1;;49.0
    W;
    A;BUFF;;96-TROUGH;2;;49.0
    D;1220099999705;;ABgene 0800;2;;49.0
    W;
    A;BUFF;;96-TROUGH;3;;49.0
    D;1220099999705;;ABgene 0800;3;;49.0
    W;
    A;BUFF;;96-TROUGH;4;;49.0
    D;1220099999705;;ABgene 0800;4;;49.0
    W;
    A;BUFF;;96-TROUGH;5;;49.0
    D;1220099999705;;ABgene 0800;5;;49.0
    W;
    A;BUFF;;96-TROUGH;6;;49.0
    D;1220099999705;;ABgene 0800;6;;49.0
    W;
    C;
    C; SCRC1 = 1220000001831
    C; SCRC2 = 1220000010734
    C; SCRC3 = 1220000005877
    C;
    C; DEST1 = 1220099999705
    """
