@api @json @tag_layout @single-sign-on @new-api
Feature: Access tag layouts through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual tag layouts through their UUID
  And I want to be able to perform other operations to individual tag layouts
  And I want to be able to do all of this only knowing the UUID of a tag layout
  And I understand I will never be able to delete a tag layout through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"
    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

  @read
  Scenario: Reading the JSON for a UUID
    Given the tag layout exists with ID 1
      And the UUID for the tag layout with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout with ID 1 is called "Example Tag Group"
      And the UUID for the plate associated with the tag layout with ID 1 is "11111111-2222-3333-4444-000000000001"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "wells of plate",

          "tag_group": {
            "name": "Example Tag Group",
            "tags": {
              "1": "ACGT",
              "2": "TGCA"
            }
          },
          "substitutions": { }
        }
      }
      """

  @tag_layout @create @barcode-service
  Scenario: 1. Creating a tag layout of an entire plate using 96 tags by pools
    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"
    Given the tag group "Example Tag Group" exists
      And the UUID for the tag group "Example Tag Group" is "00000000-1111-2222-3333-444444444444"
      And the tag group "Example Tag Group" has 20 tags

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 12, 8, 20, 12, 8, 20, 16

    When I make an authorised POST with the following JSON to the API path "/tag_layouts":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "user": "99999999-8888-7777-6666-555555555555",
          "tag_group": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "manual by pool",
          "initial_tag": 0
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG1 | TAG9  | TAG5 | TAG5  | TAG13 | TAG1 | TAG9  | TAG5 | TAG5  | TAG13 | TAG1 | TAG9  |
      | TAG2 | TAG10 | TAG6 | TAG6  | TAG14 | TAG2 | TAG10 | TAG6 | TAG6  | TAG14 | TAG2 | TAG10 |
      | TAG3 | TAG11 | TAG7 | TAG7  | TAG15 | TAG3 | TAG11 | TAG7 | TAG7  | TAG15 | TAG3 | TAG11 |
      | TAG4 | TAG12 | TAG8 | TAG8  | TAG16 | TAG4 | TAG12 | TAG8 | TAG8  | TAG16 | TAG4 | TAG12 |
      | TAG5 | TAG1  | TAG1 | TAG9  | TAG17 | TAG5 | TAG1  | TAG1 | TAG9  | TAG17 | TAG5 | TAG13 |
      | TAG6 | TAG2  | TAG2 | TAG10 | TAG18 | TAG6 | TAG2  | TAG2 | TAG10 | TAG18 | TAG6 | TAG14 |
      | TAG7 | TAG3  | TAG3 | TAG11 | TAG19 | TAG7 | TAG3  | TAG3 | TAG11 | TAG19 | TAG7 | TAG15 |
      | TAG8 | TAG4  | TAG4 | TAG12 | TAG20 | TAG8 | TAG4  | TAG4 | TAG12 | TAG20 | TAG8 | TAG16 |

  @tag_layout @create @barcode-service
  Scenario: 2. Creating a tag layout of an entire plate using 96 tags by pools
    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"

    Given the tag group "Example Tag Group" exists
      And the UUID for the tag group "Example Tag Group" is "00000000-1111-2222-3333-444444444444"
      And the tag group "Example Tag Group" has 96 tags
    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 12, 8, 20, 12, 8, 20, 16

    When I make an authorised POST with the following JSON to the API path "/tag_layouts":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "user": "99999999-8888-7777-6666-555555555555",
          "tag_group": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "manual by plate",
          "initial_tag": 0
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG1 | TAG9   | TAG17 | TAG25  | TAG33 | TAG41 | TAG49  | TAG57 | TAG65  | TAG73 | TAG81 | TAG89 |
      | TAG2 | TAG10  | TAG18 | TAG26  | TAG34 | TAG42 | TAG50  | TAG58 | TAG66  | TAG74 | TAG82 | TAG90 |
      | TAG3 | TAG11  | TAG19 | TAG27  | TAG35 | TAG43 | TAG51  | TAG59 | TAG67  | TAG75 | TAG83 | TAG91 |
      | TAG4 | TAG12  | TAG20 | TAG28  | TAG36 | TAG44 | TAG52  | TAG60 | TAG68  | TAG76 | TAG84 | TAG92 |
      | TAG5 | TAG13  | TAG21 | TAG29  | TAG37 | TAG45 | TAG53  | TAG61 | TAG69  | TAG77 | TAG85 | TAG93 |
      | TAG6 | TAG14  | TAG22 | TAG30  | TAG38 | TAG46 | TAG54  | TAG62 | TAG70  | TAG78 | TAG86 | TAG94 |
      | TAG7 | TAG15  | TAG23 | TAG31  | TAG39 | TAG47 | TAG55  | TAG63 | TAG71  | TAG79 | TAG87 | TAG95 |
      | TAG8 | TAG16  | TAG24 | TAG32  | TAG40 | TAG48 | TAG56  | TAG64 | TAG72  | TAG80 | TAG88 | TAG96 |

  @tag_layout @create @barcode-service
  Scenario: 3. Creating a tag layout of an entire plate using 96 tags by pools with empty wells
    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"
    Given the tag group "Example Tag Group" exists
      And the UUID for the tag group "Example Tag Group" is "00000000-1111-2222-3333-444444444444"
      And the tag group "Example Tag Group" has 96 tags
    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 12, 8, 20, 12, 8, 20, 16
      And well "B6" on the plate "Testing the tagging" is empty

    When I make an authorised POST with the following JSON to the API path "/tag_layouts":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "user": "99999999-8888-7777-6666-555555555555",
          "tag_group": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "manual by plate",
          "initial_tag": 0
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG1 | TAG9   | TAG17 | TAG25  | TAG33 | TAG41 | TAG48 | TAG56 | TAG64 | TAG72 | TAG80 | TAG88 |
      | TAG2 | TAG10  | TAG18 | TAG26  | TAG34 |       | TAG49 | TAG57 | TAG65 | TAG73 | TAG81 | TAG89 |
      | TAG3 | TAG11  | TAG19 | TAG27  | TAG35 | TAG42 | TAG50 | TAG58 | TAG66 | TAG74 | TAG82 | TAG90 |
      | TAG4 | TAG12  | TAG20 | TAG28  | TAG36 | TAG43 | TAG51 | TAG59 | TAG67 | TAG75 | TAG83 | TAG91 |
      | TAG5 | TAG13  | TAG21 | TAG29  | TAG37 | TAG44 | TAG52 | TAG60 | TAG68 | TAG76 | TAG84 | TAG92 |
      | TAG6 | TAG14  | TAG22 | TAG30  | TAG38 | TAG45 | TAG53 | TAG61 | TAG69 | TAG77 | TAG85 | TAG93 |
      | TAG7 | TAG15  | TAG23 | TAG31  | TAG39 | TAG46 | TAG54 | TAG62 | TAG70 | TAG78 | TAG86 | TAG94 |
      | TAG8 | TAG16  | TAG24 | TAG32  | TAG40 | TAG47 | TAG55 | TAG63 | TAG71 | TAG79 | TAG87 | TAG95 |


  @tag_layout @create @barcode-service
  Scenario: 4. Creating a tag layout of an entire plate using 96 tags by pools with an offset
    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"
    Given the tag group "Example Tag Group" exists
      And the UUID for the tag group "Example Tag Group" is "00000000-1111-2222-3333-444444444444"
      And the tag group "Example Tag Group" has 30 tags

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 12, 8, 20, 12, 8, 20, 16

    When I make an authorised POST with the following JSON to the API path "/tag_layouts":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "user": "99999999-8888-7777-6666-555555555555",
          "tag_group": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "manual by pool",
          "initial_tag": 10
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG11 | TAG19  | TAG15 | TAG15 | TAG23 | TAG11 | TAG19 | TAG15 | TAG15  | TAG23 | TAG11 | TAG19 |
      | TAG12 | TAG20  | TAG16 | TAG16 | TAG24 | TAG12 | TAG20 | TAG16 | TAG16  | TAG24 | TAG12 | TAG20 |
      | TAG13 | TAG21  | TAG17 | TAG17 | TAG25 | TAG13 | TAG21 | TAG17 | TAG17  | TAG25 | TAG13 | TAG21 |
      | TAG14 | TAG22  | TAG18 | TAG18 | TAG26 | TAG14 | TAG22 | TAG18 | TAG18  | TAG26 | TAG14 | TAG22 |
      | TAG15 | TAG11  | TAG11 | TAG19 | TAG27 | TAG15 | TAG11 | TAG11 | TAG19  | TAG27 | TAG15 | TAG23 |
      | TAG16 | TAG12  | TAG12 | TAG20 | TAG28 | TAG16 | TAG12 | TAG12 | TAG20  | TAG28 | TAG16 | TAG24 |
      | TAG17 | TAG13  | TAG13 | TAG21 | TAG29 | TAG17 | TAG13 | TAG13 | TAG21  | TAG29 | TAG17 | TAG25 |
      | TAG18 | TAG14  | TAG14 | TAG22 | TAG30 | TAG18 | TAG14 | TAG14 | TAG22  | TAG30 | TAG18 | TAG26 |

  @tag_layout @create @barcode-service
  Scenario: 5. Creating a tag layout of an entire plate using 96 tags by pools with an offset
    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"
    Given the tag group "Example Tag Group" exists
      And the UUID for the tag group "Example Tag Group" is "00000000-1111-2222-3333-444444444444"
      And the tag group "Example Tag Group" has 106 tags

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 12, 8, 20, 12, 8, 20, 16

    When I make an authorised POST with the following JSON to the API path "/tag_layouts":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "user": "99999999-8888-7777-6666-555555555555",
          "tag_group": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "manual by plate",
          "initial_tag": 10
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG11 | TAG19 | TAG27 | TAG35  | TAG43 | TAG51 | TAG59  | TAG67 | TAG75  | TAG83 | TAG91 | TAG99  |
      | TAG12 | TAG20 | TAG28 | TAG36  | TAG44 | TAG52 | TAG60  | TAG68 | TAG76  | TAG84 | TAG92 | TAG100 |
      | TAG13 | TAG21 | TAG29 | TAG37  | TAG45 | TAG53 | TAG61  | TAG69 | TAG77  | TAG85 | TAG93 | TAG101 |
      | TAG14 | TAG22 | TAG30 | TAG38  | TAG46 | TAG54 | TAG62  | TAG70 | TAG78  | TAG86 | TAG94 | TAG102 |
      | TAG15 | TAG23 | TAG31 | TAG39  | TAG47 | TAG55 | TAG63  | TAG71 | TAG79  | TAG87 | TAG95 | TAG103 |
      | TAG16 | TAG24 | TAG32 | TAG40  | TAG48 | TAG56 | TAG64  | TAG72 | TAG80  | TAG88 | TAG96 | TAG104 |
      | TAG17 | TAG25 | TAG33 | TAG41  | TAG49 | TAG57 | TAG65  | TAG73 | TAG81  | TAG89 | TAG97 | TAG105 |
      | TAG18 | TAG26 | TAG34 | TAG42  | TAG50 | TAG58 | TAG66  | TAG74 | TAG82  | TAG90 | TAG98 | TAG106 |
