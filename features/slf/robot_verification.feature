@robot_verification @barcode-service @tecan @javascript
Feature: RobotVerification
  In order to ensure that the plates for a batch are placed in the correct beds
  the batch is used to generate labels for a form to prompt the user to put the
  the correct number of plates on, and then to check the barcodes scanned.

  Scenario: 3 source plates should be ordered by bed number and scanner has CR suffix
    Given I have a released cherrypicking batch with 3 plates and the minimum robot pick is "1.0"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F
    """
    And I press "Check"
    Then I should see "Scan Robot Beds And Plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | DN1S |
    | SCRC 2 | DN10I |
    | SCRC 3 | DN5W |
    | DEST 1 | DN99999F |


    When I fill in "SCRC 1" with multiline text
    """
    4880000001780

    """
    When I fill in "DN1S" with multiline text
    """
    DN1S

    """
    When I fill in "SCRC 2" with multiline text
    """
    4880000002794

    """
    When I fill in "DN5W" with multiline text
    """
    DN5W

    """
    When I fill in "SCRC 3" with multiline text
    """
    4880000003807

    """
    When I fill in "DN10I" with multiline text
    """
    DN10I

    """
    When I fill in "DEST 1" with multiline text
    """
    4880000020729

    """
    When I fill in "DN99999F" with multiline text
    """
    DN99999F

    """
    And I press "Verify"
    Then I should see "Download Myrobot File"
    Then I follow "Download myrobot File"
    Then the downloaded robot file for batch "550000555760" and plate "DN99999F" is
    """
C;
A;BUFF Trough;;Trough 100ml;1;;9.8
D;DN99999F;;ABgene 0800;1;;9.8
W;
A;BUFF Trough;;Trough 100ml;2;;9.8
D;DN99999F;;ABgene 0800;2;;9.8
W;
A;BUFF Trough;;Trough 100ml;3;;9.8
D;DN99999F;;ABgene 0800;3;;9.8
W;
A;BUFF Trough;;Trough 100ml;4;;9.8
D;DN99999F;;ABgene 0800;4;;9.8
W;
A;BUFF Trough;;Trough 100ml;5;;9.8
D;DN99999F;;ABgene 0800;5;;9.8
W;
A;BUFF Trough;;Trough 100ml;6;;9.8
D;DN99999F;;ABgene 0800;6;;9.8
W;
C;
A;DN1S;;ABgene 0765;1;;3.2
D;DN99999F;;ABgene 0800;1;;3.2
W;
A;DN1S;;ABgene 0765;9;;3.2
D;DN99999F;;ABgene 0800;2;;3.2
W;
A;DN10I;;ABgene 0765;1;;3.2
D;DN99999F;;ABgene 0800;3;;3.2
W;
A;DN10I;;ABgene 0765;9;;3.2
D;DN99999F;;ABgene 0800;4;;3.2
W;
A;DN5W;;ABgene 0765;1;;3.2
D;DN99999F;;ABgene 0800;5;;3.2
W;
A;DN5W;;ABgene 0765;9;;3.2
D;DN99999F;;ABgene 0800;6;;3.2
W;
C;
C; SCRC1 = DN1S
C; SCRC2 = DN10I
C; SCRC3 = DN5W
C;
C; DEST1 = DN99999F
    """

  Scenario: Robot minimum volumes should be considered
    Given I have a released cherrypicking batch with 2 samples and the minimum robot pick is "5.0"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F
    """
    And I press "Check"
    Then I should see "Scan Robot Beds And Plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | DN1234567T |
    | DEST 1 | DN99999F |


    When I fill in "SCRC 1" with multiline text
    """
    4880000001780

    """
    When I fill in "DN1234567T" with multiline text
    """
    DN1234567T

    """
    When I fill in "DEST 1" with multiline text
    """
    4880000020729

    """
    When I fill in "DN99999F" with multiline text
    """
    DN99999F

    """
    And I press "Verify"
    Then I should see "Download Myrobot File"
    Then I follow "Download myrobot File"
    Then the downloaded robot file for batch "550000555760" and plate "DN99999F" is
    """
C;
A;BUFF Trough;;Trough 100ml;1;;8.0
D;DN99999F;;ABgene 0800;1;;8.0
W;
A;BUFF Trough;;Trough 100ml;2;;8.0
D;DN99999F;;ABgene 0800;2;;8.0
W;
C;
A;DN1234567T;;ABgene 0765;1;;5.0
D;DN99999F;;ABgene 0800;1;;5.0
W;
A;DN1234567T;;ABgene 0765;9;;5.0
D;DN99999F;;ABgene 0800;2;;5.0
W;
C;
C; SCRC1 = DN1234567T
C;
C; DEST1 = DN99999F
    """

Scenario: Source volumes should be updated once
    Given I have a released cherrypicking batch with 2 samples and the minimum robot pick is "5.0"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F
    """
    And I press "Check"
    Then I should see "Scan Robot Beds And Plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | DN1234567T |
    | DEST 1 | DN99999F |


    When I fill in "SCRC 1" with multiline text
    """
    4880000001780

    """
    When I fill in "DN1234567T" with multiline text
    """
    DN1234567T

    """
    When I fill in "DEST 1" with multiline text
    """
    4880000020729

    """
    When I fill in "DN99999F" with multiline text
    """
    DN99999F

    """
    And I press "Verify"
    # Then I should see "The volumes in the source plate have been updated"
    And the volume of each well in "DN1234567T" should be:
    | Well | Volume |
    | A1   | 5.0    |
    | A2   | 6.0    |
    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F
    """
    And I press "Check"
    Then I should see "Scan Robot Beds And Plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | DN1234567T |
    | DEST 1 | DN99999F |


    When I fill in "SCRC 1" with multiline text
    """
    4880000001780

    """
    When I fill in "DN1234567T" with multiline text
    """
    DN1234567T

    """
    When I fill in "DEST 1" with multiline text
    """
    4880000020729

    """
    When I fill in "DN99999F" with multiline text
    """
    DN99999F

    """
    And I press "Verify"
    # Then I should see "The volumes in the source plate have been updated"
    And the volume of each well in "DN1234567T" should be:
    | Well | Volume |
    | A1   | 5.0    |
    | A2   | 6.0    |


  Scenario: Robot minimum volumes should be considered for water
    Given I have a released low concentration cherrypicking batch with 2 samples and the minimum robot pick is "5.0"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697
    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853
    """
    When I fill in "Scan worksheet" with multiline text
    """
    550000555760
    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F
    """
    And I press "Check"
    Then I should see "Scan Robot Beds And Plates"
    And the source plates should be sorted by bed:
    | Bed    | Plate ID      |
    | SCRC 1 | DN1234567T |
    | DEST 1 | DN99999F |


    When I fill in "SCRC 1" with multiline text
    """
    4880000001780

    """
    When I fill in "DN1234567T" with multiline text
    """
    DN1234567T

    """
    When I fill in "DEST 1" with multiline text
    """
    4880000020729

    """
    When I fill in "DN99999F" with multiline text
    """
    DN99999F

    """
    And I press "Verify"
    Then I should see "Download Myrobot File"
    Then I follow "Download myrobot File"
    Then the downloaded robot file for batch "550000555760" and plate "DN99999F" is
    """
C;
A;BUFF Trough;;Trough 100ml;1;;5.0
D;DN99999F;;ABgene 0800;1;;5.0
W;
A;BUFF Trough;;Trough 100ml;2;;5.0
D;DN99999F;;ABgene 0800;2;;5.0
W;
C;
A;DN1234567T;;ABgene 0765;1;;10.0
D;DN99999F;;ABgene 0800;1;;10.0
W;
A;DN1234567T;;ABgene 0765;9;;11.0
D;DN99999F;;ABgene 0800;2;;11.0
W;
C;
C; SCRC1 = DN1234567T
C;
C; DEST1 = DN99999F
    """


  Scenario: Barcode scanners with carriage return should not submit page until end
    Given I have a released cherrypicking batch with 96 samples and the minimum robot pick is "1.0"
    And user "user" has a user barcode of "ID41440E"

    Given I am on the robot verification page
    When I fill in "Scan user ID" with multiline text
    """
    2470041440697


    """
    When I fill in "Scan robot" with multiline text
    """
    4880000444853

    """

    When I fill in "Scan worksheet" with multiline text
    """
    550000555760

    """
    When I fill in "Scan destination plate" with multiline text
    """
    DN99999F

    """

    # the last step (with a carriage reture) trigger the check
    # and launch a new page. We want capyra to wait the check is finished
    # before checking the page. Filling something does it.

    When I fill in the following:
    | SCRC 1        | 4880000001780 |
    | DN1234567T | DN1234567T |
    | DEST 1        | 4880000020729 |
    | DN99999F | DN99999F |

    # we moved this step here, because we need the page to be loaded before checking it.
    Then I should see "Scan Robot Beds And Plates"

    And I press "Verify"
    Then I should see "Download Myrobot File"
    Then I follow "Download myrobot File"
    Then the downloaded robot file for batch "550000555760" and plate "DN99999F" is
"""
C;
A;BUFF Trough;;Trough 100ml;1;;9.8
D;DN99999F;;ABgene 0800;1;;9.8
W;
A;BUFF Trough;;Trough 100ml;2;;10.0
D;DN99999F;;ABgene 0800;2;;10.0
W;
A;BUFF Trough;;Trough 100ml;3;;10.2
D;DN99999F;;ABgene 0800;3;;10.2
W;
A;BUFF Trough;;Trough 100ml;4;;10.3
D;DN99999F;;ABgene 0800;4;;10.3
W;
A;BUFF Trough;;Trough 100ml;5;;10.4
D;DN99999F;;ABgene 0800;5;;10.4
W;
A;BUFF Trough;;Trough 100ml;6;;10.0
D;DN99999F;;ABgene 0800;6;;10.0
W;
A;BUFF Trough;;Trough 100ml;7;;10.1
D;DN99999F;;ABgene 0800;7;;10.1
W;
A;BUFF Trough;;Trough 100ml;8;;10.3
D;DN99999F;;ABgene 0800;8;;10.3
W;
A;BUFF Trough;;Trough 100ml;9;;9.8
D;DN99999F;;ABgene 0800;9;;9.8
W;
A;BUFF Trough;;Trough 100ml;10;;10.0
D;DN99999F;;ABgene 0800;10;;10.0
W;
A;BUFF Trough;;Trough 100ml;11;;10.2
D;DN99999F;;ABgene 0800;11;;10.2
W;
A;BUFF Trough;;Trough 100ml;12;;10.3
D;DN99999F;;ABgene 0800;12;;10.3
W;
A;BUFF Trough;;Trough 100ml;13;;10.4
D;DN99999F;;ABgene 0800;13;;10.4
W;
A;BUFF Trough;;Trough 100ml;14;;10.0
D;DN99999F;;ABgene 0800;14;;10.0
W;
A;BUFF Trough;;Trough 100ml;15;;10.1
D;DN99999F;;ABgene 0800;15;;10.1
W;
A;BUFF Trough;;Trough 100ml;16;;10.3
D;DN99999F;;ABgene 0800;16;;10.3
W;
A;BUFF Trough;;Trough 100ml;17;;9.9
D;DN99999F;;ABgene 0800;17;;9.9
W;
A;BUFF Trough;;Trough 100ml;18;;10.0
D;DN99999F;;ABgene 0800;18;;10.0
W;
A;BUFF Trough;;Trough 100ml;19;;10.2
D;DN99999F;;ABgene 0800;19;;10.2
W;
A;BUFF Trough;;Trough 100ml;20;;10.3
D;DN99999F;;ABgene 0800;20;;10.3
W;
A;BUFF Trough;;Trough 100ml;21;;9.8
D;DN99999F;;ABgene 0800;21;;9.8
W;
A;BUFF Trough;;Trough 100ml;22;;10.0
D;DN99999F;;ABgene 0800;22;;10.0
W;
A;BUFF Trough;;Trough 100ml;23;;10.2
D;DN99999F;;ABgene 0800;23;;10.2
W;
A;BUFF Trough;;Trough 100ml;24;;10.3
D;DN99999F;;ABgene 0800;24;;10.3
W;
A;BUFF Trough;;Trough 100ml;25;;9.9
D;DN99999F;;ABgene 0800;25;;9.9
W;
A;BUFF Trough;;Trough 100ml;26;;10.0
D;DN99999F;;ABgene 0800;26;;10.0
W;
A;BUFF Trough;;Trough 100ml;27;;10.2
D;DN99999F;;ABgene 0800;27;;10.2
W;
A;BUFF Trough;;Trough 100ml;28;;10.3
D;DN99999F;;ABgene 0800;28;;10.3
W;
A;BUFF Trough;;Trough 100ml;29;;9.8
D;DN99999F;;ABgene 0800;29;;9.8
W;
A;BUFF Trough;;Trough 100ml;30;;10.0
D;DN99999F;;ABgene 0800;30;;10.0
W;
A;BUFF Trough;;Trough 100ml;31;;10.2
D;DN99999F;;ABgene 0800;31;;10.2
W;
A;BUFF Trough;;Trough 100ml;32;;10.3
D;DN99999F;;ABgene 0800;32;;10.3
W;
A;BUFF Trough;;Trough 100ml;33;;9.9
D;DN99999F;;ABgene 0800;33;;9.9
W;
A;BUFF Trough;;Trough 100ml;34;;10.1
D;DN99999F;;ABgene 0800;34;;10.1
W;
A;BUFF Trough;;Trough 100ml;35;;10.2
D;DN99999F;;ABgene 0800;35;;10.2
W;
A;BUFF Trough;;Trough 100ml;36;;10.3
D;DN99999F;;ABgene 0800;36;;10.3
W;
A;BUFF Trough;;Trough 100ml;37;;9.9
D;DN99999F;;ABgene 0800;37;;9.9
W;
A;BUFF Trough;;Trough 100ml;38;;10.0
D;DN99999F;;ABgene 0800;38;;10.0
W;
A;BUFF Trough;;Trough 100ml;39;;10.2
D;DN99999F;;ABgene 0800;39;;10.2
W;
A;BUFF Trough;;Trough 100ml;40;;10.3
D;DN99999F;;ABgene 0800;40;;10.3
W;
A;BUFF Trough;;Trough 100ml;41;;9.9
D;DN99999F;;ABgene 0800;41;;9.9
W;
A;BUFF Trough;;Trough 100ml;42;;10.1
D;DN99999F;;ABgene 0800;42;;10.1
W;
A;BUFF Trough;;Trough 100ml;43;;10.2
D;DN99999F;;ABgene 0800;43;;10.2
W;
A;BUFF Trough;;Trough 100ml;44;;10.4
D;DN99999F;;ABgene 0800;44;;10.4
W;
A;BUFF Trough;;Trough 100ml;45;;9.9
D;DN99999F;;ABgene 0800;45;;9.9
W;
A;BUFF Trough;;Trough 100ml;46;;10.0
D;DN99999F;;ABgene 0800;46;;10.0
W;
A;BUFF Trough;;Trough 100ml;47;;10.2
D;DN99999F;;ABgene 0800;47;;10.2
W;
A;BUFF Trough;;Trough 100ml;48;;10.3
D;DN99999F;;ABgene 0800;48;;10.3
W;
A;BUFF Trough;;Trough 100ml;49;;9.9
D;DN99999F;;ABgene 0800;49;;9.9
W;
A;BUFF Trough;;Trough 100ml;50;;10.1
D;DN99999F;;ABgene 0800;50;;10.1
W;
A;BUFF Trough;;Trough 100ml;51;;10.2
D;DN99999F;;ABgene 0800;51;;10.2
W;
A;BUFF Trough;;Trough 100ml;52;;10.4
D;DN99999F;;ABgene 0800;52;;10.4
W;
A;BUFF Trough;;Trough 100ml;53;;9.9
D;DN99999F;;ABgene 0800;53;;9.9
W;
A;BUFF Trough;;Trough 100ml;54;;10.1
D;DN99999F;;ABgene 0800;54;;10.1
W;
A;BUFF Trough;;Trough 100ml;55;;10.2
D;DN99999F;;ABgene 0800;55;;10.2
W;
A;BUFF Trough;;Trough 100ml;56;;10.3
D;DN99999F;;ABgene 0800;56;;10.3
W;
A;BUFF Trough;;Trough 100ml;57;;9.9
D;DN99999F;;ABgene 0800;57;;9.9
W;
A;BUFF Trough;;Trough 100ml;58;;10.1
D;DN99999F;;ABgene 0800;58;;10.1
W;
A;BUFF Trough;;Trough 100ml;59;;10.2
D;DN99999F;;ABgene 0800;59;;10.2
W;
A;BUFF Trough;;Trough 100ml;60;;10.4
D;DN99999F;;ABgene 0800;60;;10.4
W;
A;BUFF Trough;;Trough 100ml;61;;9.9
D;DN99999F;;ABgene 0800;61;;9.9
W;
A;BUFF Trough;;Trough 100ml;62;;10.1
D;DN99999F;;ABgene 0800;62;;10.1
W;
A;BUFF Trough;;Trough 100ml;63;;10.2
D;DN99999F;;ABgene 0800;63;;10.2
W;
A;BUFF Trough;;Trough 100ml;64;;10.4
D;DN99999F;;ABgene 0800;64;;10.4
W;
A;BUFF Trough;;Trough 100ml;65;;9.9
D;DN99999F;;ABgene 0800;65;;9.9
W;
A;BUFF Trough;;Trough 100ml;66;;10.1
D;DN99999F;;ABgene 0800;66;;10.1
W;
A;BUFF Trough;;Trough 100ml;67;;10.3
D;DN99999F;;ABgene 0800;67;;10.3
W;
A;BUFF Trough;;Trough 100ml;68;;10.4
D;DN99999F;;ABgene 0800;68;;10.4
W;
A;BUFF Trough;;Trough 100ml;69;;9.9
D;DN99999F;;ABgene 0800;69;;9.9
W;
A;BUFF Trough;;Trough 100ml;70;;10.1
D;DN99999F;;ABgene 0800;70;;10.1
W;
A;BUFF Trough;;Trough 100ml;71;;10.2
D;DN99999F;;ABgene 0800;71;;10.2
W;
A;BUFF Trough;;Trough 100ml;72;;10.4
D;DN99999F;;ABgene 0800;72;;10.4
W;
A;BUFF Trough;;Trough 100ml;73;;10.0
D;DN99999F;;ABgene 0800;73;;10.0
W;
A;BUFF Trough;;Trough 100ml;74;;10.1
D;DN99999F;;ABgene 0800;74;;10.1
W;
A;BUFF Trough;;Trough 100ml;75;;10.3
D;DN99999F;;ABgene 0800;75;;10.3
W;
A;BUFF Trough;;Trough 100ml;76;;10.4
D;DN99999F;;ABgene 0800;76;;10.4
W;
A;BUFF Trough;;Trough 100ml;77;;9.9
D;DN99999F;;ABgene 0800;77;;9.9
W;
A;BUFF Trough;;Trough 100ml;78;;10.1
D;DN99999F;;ABgene 0800;78;;10.1
W;
A;BUFF Trough;;Trough 100ml;79;;10.2
D;DN99999F;;ABgene 0800;79;;10.2
W;
A;BUFF Trough;;Trough 100ml;80;;10.4
D;DN99999F;;ABgene 0800;80;;10.4
W;
A;BUFF Trough;;Trough 100ml;81;;10.0
D;DN99999F;;ABgene 0800;81;;10.0
W;
A;BUFF Trough;;Trough 100ml;82;;10.1
D;DN99999F;;ABgene 0800;82;;10.1
W;
A;BUFF Trough;;Trough 100ml;83;;10.3
D;DN99999F;;ABgene 0800;83;;10.3
W;
A;BUFF Trough;;Trough 100ml;84;;10.4
D;DN99999F;;ABgene 0800;84;;10.4
W;
A;BUFF Trough;;Trough 100ml;85;;9.9
D;DN99999F;;ABgene 0800;85;;9.9
W;
A;BUFF Trough;;Trough 100ml;86;;10.1
D;DN99999F;;ABgene 0800;86;;10.1
W;
A;BUFF Trough;;Trough 100ml;87;;10.3
D;DN99999F;;ABgene 0800;87;;10.3
W;
A;BUFF Trough;;Trough 100ml;88;;10.4
D;DN99999F;;ABgene 0800;88;;10.4
W;
A;BUFF Trough;;Trough 100ml;89;;10.0
D;DN99999F;;ABgene 0800;89;;10.0
W;
A;BUFF Trough;;Trough 100ml;90;;10.1
D;DN99999F;;ABgene 0800;90;;10.1
W;
A;BUFF Trough;;Trough 100ml;91;;10.3
D;DN99999F;;ABgene 0800;91;;10.3
W;
A;BUFF Trough;;Trough 100ml;92;;10.4
D;DN99999F;;ABgene 0800;92;;10.4
W;
A;BUFF Trough;;Trough 100ml;93;;10.0
D;DN99999F;;ABgene 0800;93;;10.0
W;
A;BUFF Trough;;Trough 100ml;94;;10.1
D;DN99999F;;ABgene 0800;94;;10.1
W;
A;BUFF Trough;;Trough 100ml;95;;10.3
D;DN99999F;;ABgene 0800;95;;10.3
W;
A;BUFF Trough;;Trough 100ml;96;;10.4
D;DN99999F;;ABgene 0800;96;;10.4
W;
C;
A;DN1234567T;;ABgene 0765;1;;3.2
D;DN99999F;;ABgene 0800;1;;3.2
W;
A;DN1234567T;;ABgene 0765;2;;3.0
D;DN99999F;;ABgene 0800;2;;3.0
W;
A;DN1234567T;;ABgene 0765;3;;2.8
D;DN99999F;;ABgene 0800;3;;2.8
W;
A;DN1234567T;;ABgene 0765;4;;2.7
D;DN99999F;;ABgene 0800;4;;2.7
W;
A;DN1234567T;;ABgene 0765;5;;2.6
D;DN99999F;;ABgene 0800;5;;2.6
W;
A;DN1234567T;;ABgene 0765;6;;3.0
D;DN99999F;;ABgene 0800;6;;3.0
W;
A;DN1234567T;;ABgene 0765;7;;2.9
D;DN99999F;;ABgene 0800;7;;2.9
W;
A;DN1234567T;;ABgene 0765;8;;2.7
D;DN99999F;;ABgene 0800;8;;2.7
W;
A;DN1234567T;;ABgene 0765;9;;3.2
D;DN99999F;;ABgene 0800;9;;3.2
W;
A;DN1234567T;;ABgene 0765;10;;3.0
D;DN99999F;;ABgene 0800;10;;3.0
W;
A;DN1234567T;;ABgene 0765;11;;2.8
D;DN99999F;;ABgene 0800;11;;2.8
W;
A;DN1234567T;;ABgene 0765;12;;2.7
D;DN99999F;;ABgene 0800;12;;2.7
W;
A;DN1234567T;;ABgene 0765;13;;2.6
D;DN99999F;;ABgene 0800;13;;2.6
W;
A;DN1234567T;;ABgene 0765;14;;3.0
D;DN99999F;;ABgene 0800;14;;3.0
W;
A;DN1234567T;;ABgene 0765;15;;2.9
D;DN99999F;;ABgene 0800;15;;2.9
W;
A;DN1234567T;;ABgene 0765;16;;2.7
D;DN99999F;;ABgene 0800;16;;2.7
W;
A;DN1234567T;;ABgene 0765;17;;3.1
D;DN99999F;;ABgene 0800;17;;3.1
W;
A;DN1234567T;;ABgene 0765;18;;3.0
D;DN99999F;;ABgene 0800;18;;3.0
W;
A;DN1234567T;;ABgene 0765;19;;2.8
D;DN99999F;;ABgene 0800;19;;2.8
W;
A;DN1234567T;;ABgene 0765;20;;2.7
D;DN99999F;;ABgene 0800;20;;2.7
W;
A;DN1234567T;;ABgene 0765;21;;3.2
D;DN99999F;;ABgene 0800;21;;3.2
W;
A;DN1234567T;;ABgene 0765;22;;3.0
D;DN99999F;;ABgene 0800;22;;3.0
W;
A;DN1234567T;;ABgene 0765;23;;2.8
D;DN99999F;;ABgene 0800;23;;2.8
W;
A;DN1234567T;;ABgene 0765;24;;2.7
D;DN99999F;;ABgene 0800;24;;2.7
W;
A;DN1234567T;;ABgene 0765;25;;3.1
D;DN99999F;;ABgene 0800;25;;3.1
W;
A;DN1234567T;;ABgene 0765;26;;3.0
D;DN99999F;;ABgene 0800;26;;3.0
W;
A;DN1234567T;;ABgene 0765;27;;2.8
D;DN99999F;;ABgene 0800;27;;2.8
W;
A;DN1234567T;;ABgene 0765;28;;2.7
D;DN99999F;;ABgene 0800;28;;2.7
W;
A;DN1234567T;;ABgene 0765;29;;3.2
D;DN99999F;;ABgene 0800;29;;3.2
W;
A;DN1234567T;;ABgene 0765;30;;3.0
D;DN99999F;;ABgene 0800;30;;3.0
W;
A;DN1234567T;;ABgene 0765;31;;2.8
D;DN99999F;;ABgene 0800;31;;2.8
W;
A;DN1234567T;;ABgene 0765;32;;2.7
D;DN99999F;;ABgene 0800;32;;2.7
W;
A;DN1234567T;;ABgene 0765;33;;3.1
D;DN99999F;;ABgene 0800;33;;3.1
W;
A;DN1234567T;;ABgene 0765;34;;2.9
D;DN99999F;;ABgene 0800;34;;2.9
W;
A;DN1234567T;;ABgene 0765;35;;2.8
D;DN99999F;;ABgene 0800;35;;2.8
W;
A;DN1234567T;;ABgene 0765;36;;2.7
D;DN99999F;;ABgene 0800;36;;2.7
W;
A;DN1234567T;;ABgene 0765;37;;3.1
D;DN99999F;;ABgene 0800;37;;3.1
W;
A;DN1234567T;;ABgene 0765;38;;3.0
D;DN99999F;;ABgene 0800;38;;3.0
W;
A;DN1234567T;;ABgene 0765;39;;2.8
D;DN99999F;;ABgene 0800;39;;2.8
W;
A;DN1234567T;;ABgene 0765;40;;2.7
D;DN99999F;;ABgene 0800;40;;2.7
W;
A;DN1234567T;;ABgene 0765;41;;3.1
D;DN99999F;;ABgene 0800;41;;3.1
W;
A;DN1234567T;;ABgene 0765;42;;2.9
D;DN99999F;;ABgene 0800;42;;2.9
W;
A;DN1234567T;;ABgene 0765;43;;2.8
D;DN99999F;;ABgene 0800;43;;2.8
W;
A;DN1234567T;;ABgene 0765;44;;2.6
D;DN99999F;;ABgene 0800;44;;2.6
W;
A;DN1234567T;;ABgene 0765;45;;3.1
D;DN99999F;;ABgene 0800;45;;3.1
W;
A;DN1234567T;;ABgene 0765;46;;3.0
D;DN99999F;;ABgene 0800;46;;3.0
W;
A;DN1234567T;;ABgene 0765;47;;2.8
D;DN99999F;;ABgene 0800;47;;2.8
W;
A;DN1234567T;;ABgene 0765;48;;2.7
D;DN99999F;;ABgene 0800;48;;2.7
W;
A;DN1234567T;;ABgene 0765;49;;3.1
D;DN99999F;;ABgene 0800;49;;3.1
W;
A;DN1234567T;;ABgene 0765;50;;2.9
D;DN99999F;;ABgene 0800;50;;2.9
W;
A;DN1234567T;;ABgene 0765;51;;2.8
D;DN99999F;;ABgene 0800;51;;2.8
W;
A;DN1234567T;;ABgene 0765;52;;2.6
D;DN99999F;;ABgene 0800;52;;2.6
W;
A;DN1234567T;;ABgene 0765;53;;3.1
D;DN99999F;;ABgene 0800;53;;3.1
W;
A;DN1234567T;;ABgene 0765;54;;2.9
D;DN99999F;;ABgene 0800;54;;2.9
W;
A;DN1234567T;;ABgene 0765;55;;2.8
D;DN99999F;;ABgene 0800;55;;2.8
W;
A;DN1234567T;;ABgene 0765;56;;2.7
D;DN99999F;;ABgene 0800;56;;2.7
W;
A;DN1234567T;;ABgene 0765;57;;3.1
D;DN99999F;;ABgene 0800;57;;3.1
W;
A;DN1234567T;;ABgene 0765;58;;2.9
D;DN99999F;;ABgene 0800;58;;2.9
W;
A;DN1234567T;;ABgene 0765;59;;2.8
D;DN99999F;;ABgene 0800;59;;2.8
W;
A;DN1234567T;;ABgene 0765;60;;2.6
D;DN99999F;;ABgene 0800;60;;2.6
W;
A;DN1234567T;;ABgene 0765;61;;3.1
D;DN99999F;;ABgene 0800;61;;3.1
W;
A;DN1234567T;;ABgene 0765;62;;2.9
D;DN99999F;;ABgene 0800;62;;2.9
W;
A;DN1234567T;;ABgene 0765;63;;2.8
D;DN99999F;;ABgene 0800;63;;2.8
W;
A;DN1234567T;;ABgene 0765;64;;2.6
D;DN99999F;;ABgene 0800;64;;2.6
W;
A;DN1234567T;;ABgene 0765;65;;3.1
D;DN99999F;;ABgene 0800;65;;3.1
W;
A;DN1234567T;;ABgene 0765;66;;2.9
D;DN99999F;;ABgene 0800;66;;2.9
W;
A;DN1234567T;;ABgene 0765;67;;2.7
D;DN99999F;;ABgene 0800;67;;2.7
W;
A;DN1234567T;;ABgene 0765;68;;2.6
D;DN99999F;;ABgene 0800;68;;2.6
W;
A;DN1234567T;;ABgene 0765;69;;3.1
D;DN99999F;;ABgene 0800;69;;3.1
W;
A;DN1234567T;;ABgene 0765;70;;2.9
D;DN99999F;;ABgene 0800;70;;2.9
W;
A;DN1234567T;;ABgene 0765;71;;2.8
D;DN99999F;;ABgene 0800;71;;2.8
W;
A;DN1234567T;;ABgene 0765;72;;2.6
D;DN99999F;;ABgene 0800;72;;2.6
W;
A;DN1234567T;;ABgene 0765;73;;3.0
D;DN99999F;;ABgene 0800;73;;3.0
W;
A;DN1234567T;;ABgene 0765;74;;2.9
D;DN99999F;;ABgene 0800;74;;2.9
W;
A;DN1234567T;;ABgene 0765;75;;2.7
D;DN99999F;;ABgene 0800;75;;2.7
W;
A;DN1234567T;;ABgene 0765;76;;2.6
D;DN99999F;;ABgene 0800;76;;2.6
W;
A;DN1234567T;;ABgene 0765;77;;3.1
D;DN99999F;;ABgene 0800;77;;3.1
W;
A;DN1234567T;;ABgene 0765;78;;2.9
D;DN99999F;;ABgene 0800;78;;2.9
W;
A;DN1234567T;;ABgene 0765;79;;2.8
D;DN99999F;;ABgene 0800;79;;2.8
W;
A;DN1234567T;;ABgene 0765;80;;2.6
D;DN99999F;;ABgene 0800;80;;2.6
W;
A;DN1234567T;;ABgene 0765;81;;3.0
D;DN99999F;;ABgene 0800;81;;3.0
W;
A;DN1234567T;;ABgene 0765;82;;2.9
D;DN99999F;;ABgene 0800;82;;2.9
W;
A;DN1234567T;;ABgene 0765;83;;2.7
D;DN99999F;;ABgene 0800;83;;2.7
W;
A;DN1234567T;;ABgene 0765;84;;2.6
D;DN99999F;;ABgene 0800;84;;2.6
W;
A;DN1234567T;;ABgene 0765;85;;3.1
D;DN99999F;;ABgene 0800;85;;3.1
W;
A;DN1234567T;;ABgene 0765;86;;2.9
D;DN99999F;;ABgene 0800;86;;2.9
W;
A;DN1234567T;;ABgene 0765;87;;2.7
D;DN99999F;;ABgene 0800;87;;2.7
W;
A;DN1234567T;;ABgene 0765;88;;2.6
D;DN99999F;;ABgene 0800;88;;2.6
W;
A;DN1234567T;;ABgene 0765;89;;3.0
D;DN99999F;;ABgene 0800;89;;3.0
W;
A;DN1234567T;;ABgene 0765;90;;2.9
D;DN99999F;;ABgene 0800;90;;2.9
W;
A;DN1234567T;;ABgene 0765;91;;2.7
D;DN99999F;;ABgene 0800;91;;2.7
W;
A;DN1234567T;;ABgene 0765;92;;2.6
D;DN99999F;;ABgene 0800;92;;2.6
W;
A;DN1234567T;;ABgene 0765;93;;3.0
D;DN99999F;;ABgene 0800;93;;3.0
W;
A;DN1234567T;;ABgene 0765;94;;2.9
D;DN99999F;;ABgene 0800;94;;2.9
W;
A;DN1234567T;;ABgene 0765;95;;2.7
D;DN99999F;;ABgene 0800;95;;2.7
W;
A;DN1234567T;;ABgene 0765;96;;2.6
D;DN99999F;;ABgene 0800;96;;2.6
W;
C;
C; SCRC1 = DN1234567T
C;
C; DEST1 = DN99999F
"""
