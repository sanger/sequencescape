@api @json @transfer @single-sign-on @new-api
Feature: Conduct multiple transfers through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to perform transfers between arbitary number of plates

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a bulk transfer between two plates
    Given a source transfer plate called "Source plate A" exists
      And the UUID for the plate "Source plate A" is "11111111-2222-3333-4444-000000000001"
      And a source transfer plate called "Source plate B" exists
      And the UUID for the plate "Source plate B" is "11111111-2222-3333-4444-000000000002"
      And a destination transfer plate called "Destination plate A" exists
      And the UUID for the plate "Destination plate A" is "11111111-2222-3333-4444-000000000003"
      And a destination transfer plate called "Destination plate B" exists
      And the UUID for the plate "Destination plate B" is "11111111-2222-3333-4444-000000000004"

      Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

      Given the UUID of the next bulk transfer created will be "00000000-1111-2222-3333-444444444444"

      When I make an authorised POST with the following JSON to the API path "/bulk_transfers":
      """
      {
        "bulk_transfer": {
          "well_transfers":[
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"A1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"A1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"B1",
              "destination_uuid": "11111111-2222-3333-4444-000000000004", "destination_location":"A1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000002", "source_location":"A1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"B1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000002", "source_location":"B1",
              "destination_uuid": "11111111-2222-3333-4444-000000000004", "destination_location":"B1"
            }
          ],
          "user": "99999999-8888-7777-6666-555555555555"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the transfers from the plate "Source plate A" to the plate "Destination plate A" should be:
      | source | destination |
      | A1     | A1          |
    Then the transfers from the plate "Source plate A" to the plate "Destination plate B" should be:
      | source | destination |
      | B1     | A1          |
    Then the transfers from the plate "Source plate B" to the plate "Destination plate A" should be:
      | source | destination |
      | A1     | B1          |
    Then the transfers from the plate "Source plate B" to the plate "Destination plate B" should be:
      | source | destination |
      | B1     | B1          |

     And the JSON should match the following for the specified fields:
      """
      {
        "bulk_transfer": {
          "transfers": {
            "size":4,
            "actions": { "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/transfers" }
          },
          "user": {"uuid": "99999999-8888-7777-6666-555555555555"}
        }
      }
      """
      Given the number of results returned by the API per page is 5
      When I GET the API path "/00000000-1111-2222-3333-444444444444/transfers"
      Then the HTTP response should be "200 OK"
      And the JSON should match the following for the specified fields:
        """
        {
          "transfers": [
            {
              "source": {
                "uuid": "11111111-2222-3333-4444-000000000001"
              },
              "destination": {
                "uuid": "11111111-2222-3333-4444-000000000003"
              },
              "transfers": {
                "A1": ["A1"]
              }
            },
            {
              "source": {
                "uuid": "11111111-2222-3333-4444-000000000001"
              },
              "destination": {
                "uuid": "11111111-2222-3333-4444-000000000004"
              },
              "transfers": {
                "B1": ["A1"]
              }
            },
            {
              "source": {
                "uuid": "11111111-2222-3333-4444-000000000002"
              },
              "destination": {
                "uuid": "11111111-2222-3333-4444-000000000003"
              },
              "transfers": {
                "A1": ["B1"]
              }
            },
            {
              "source": {
                "uuid": "11111111-2222-3333-4444-000000000002"
              },
              "destination": {
                "uuid": "11111111-2222-3333-4444-000000000004"
              },
              "transfers": {
                "B1": ["B1"]
              }
            }
          ]
        }
        """

  Scenario: Trtansfering the same well to two locations
    Given a source transfer plate called "Source plate A" exists
      And the UUID for the plate "Source plate A" is "11111111-2222-3333-4444-000000000001"
      And a destination transfer plate called "Destination plate A" exists
      And the UUID for the plate "Destination plate A" is "11111111-2222-3333-4444-000000000003"


      Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

      Given the UUID of the next bulk transfer created will be "00000000-1111-2222-3333-444444444444"

      When I make an authorised POST with the following JSON to the API path "/bulk_transfers":
      """
      {
        "bulk_transfer": {
          "well_transfers":[
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"A1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"A1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"B1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"A1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"A1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"B1"
            },
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"B1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"B1"
            }
          ],
          "user": "99999999-8888-7777-6666-555555555555"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the transfers from the plate "Source plate A" to the plate "Destination plate A" should be:
      | source | destination |
      | A1     | A1          |
      | A1     | B1          |
      | B1     | A1          |
      | A1     | B1          |

     And the JSON should match the following for the specified fields:
      """
      {
        "bulk_transfer": {
          "transfers": {
            "size":1,
            "actions": { "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/transfers" }
          },
          "user": {"uuid": "99999999-8888-7777-6666-555555555555"}
        }
      }
      """
      Given the number of results returned by the API per page is 5
      When I GET the API path "/00000000-1111-2222-3333-444444444444/transfers"
      Then the HTTP response should be "200 OK"
      And the JSON should match the following for the specified fields:
        """
        {
          "transfers": [
            {
              "source": {
                "uuid": "11111111-2222-3333-4444-000000000001"
              },
              "destination": {
                "uuid": "11111111-2222-3333-4444-000000000003"
              },
              "transfers": {
                "A1": ["A1","B1"],
                "B1": ["A1","B1"]
              }
            }
          ]
        }
        """

  @read
  Scenario: Creating with an invalid target
    Given a source transfer plate called "Source plate A" exists
      And the UUID for the plate "Source plate A" is "11111111-2222-3333-4444-000000000001"
      And a library tube called "Invalid Destination" exists
      And the UUID for the library tube "Invalid Destination" is "11111111-2222-3333-4444-000000000003"

      Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

      Given the UUID of the next bulk transfer created will be "00000000-1111-2222-3333-444444444444"

      When I make an authorised POST with the following JSON to the API path "/bulk_transfers":
      """
      {
        "bulk_transfer": {
          "well_transfers":[
            {
              "source_uuid": "11111111-2222-3333-4444-000000000001", "source_location":"A1",
              "destination_uuid": "11111111-2222-3333-4444-000000000003", "destination_location":"A1"
            }
          ],
          "user": "99999999-8888-7777-6666-555555555555"
        }
      }
      """
    Then the HTTP response should be "422"

     And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "destination":["is not a plate"]
        }
      }
      """

