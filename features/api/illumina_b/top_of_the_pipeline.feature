@api @json @single-sign-on @new-api @barcode-service
Feature: The top of the Illumina-B pipeline
  At the top of the illumina b pipeline a stock plate arrives and an illumina-b is processed.
  "Processed" means that the plate is created from the stock plate, the entire contents of the stock
  plate is transferred to it, and the plate is started.  The act of starting the plate should change the
  state of the illumina b library creation requests it is the source asset for, but any other state changes
  should have no affect on these requests.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "SQPD-1000002"

      And the UUID for the transfer template "Transfer columns 1-12" is "22222222-3333-4444-5555-000000000001"
      And the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"
      And the UUID of the next plate creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next state change created will be "44444444-5555-6666-7777-000000000001"

  @authorised
  Scenario: Dealing with the initial plate in the pipeline
    Given the UUID for the plate purpose "ILB_STD_INPUT" is "11111111-2222-3333-4444-000000000001"
      And a full plate called "Testing the API" exists with purpose "ILB_STD_INPUT" and barcode "1000001"
      # And a "ILB_STD_INPUT" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      # And all wells on the plate "Testing the API" have unique samples

    Given the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"

    Given the UUID for the plate purpose "ILB_STD_COVARIS" is "11111111-2222-3333-4444-000000000002"
      And the UUID of the next plate created will be "00000000-1111-2222-3333-000000000002"

    # Find the plate by barcode
    When I POST the following JSON to the API path "/33333333-4444-5555-6666-000000000001/first":
      """
      {
        "search": {
          "barcode": "1221000001777"
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "name": "Testing the API",
          "uuid": "00000000-1111-2222-3333-000000000001",
          "state": "passed"
        }
      }
      """

    # Create the child plate
    When I make an authorised POST with the following JSON to the API path "/plate_creations":
      """
      {
        "plate_creation": {
          "user": "99999999-8888-7777-6666-555555555555",
          "parent": "00000000-1111-2222-3333-000000000001",
          "child_purpose": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate_creation": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "parent": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000001"
            }
          },
          "child": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "child_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """

    # Make the transfers between the two plates
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "00000000-1111-2222-3333-000000000001",
          "destination": "00000000-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "00000000-1111-2222-3333-000000000001"
          },
          "destination": {
            "uuid": "00000000-1111-2222-3333-000000000002"
          },
          "transfers": {
            "A1":  "A1",
            "A2":  "A2",

            "B1":  "B1",
            "B2":  "B2",

            "C1":  "C1",
            "C2":  "C2",

            "D1":  "D1",
            "D2":  "D2",

            "E1":  "E1",
            "E2":  "E2",

            "F1":  "F1",
            "F2":  "F2",

            "G1":  "G1",
            "G2":  "G2",

            "H1":  "H1",
            "H2":  "H2"
          }
        }
      }
      """

    # Find the child plate by barcode
    When I POST the following JSON to the API path "/33333333-4444-5555-6666-000000000001/first":
      """
      {
        "search": {
          "barcode": "1221000002781"
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "name": "Plate DN1000002N",
          "uuid": "00000000-1111-2222-3333-000000000002"
        }
      }
      """

    # Change the state of the plate to started
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "started"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/44444444-5555-6666-7777-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "started",
          "previous_state": "pending"
        }
      }
      """

    # Check all of the states are correct
    Then the state of the plate with UUID "00000000-1111-2222-3333-000000000002" should be "started"
     And the state of all the transfer requests to the plate with UUID "00000000-1111-2222-3333-000000000002" should be "started"
     And the state of all the illumina-b library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"

    # Now change the state of the plate to passed
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "passed"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "passed",
          "previous_state": "started"
        }
      }
      """

    # Check all of the states are correct
    Then the state of the plate with UUID "00000000-1111-2222-3333-000000000002" should be "passed"
     And the state of all the transfer requests to the plate with UUID "00000000-1111-2222-3333-000000000002" should be "passed"
     And the state of all the illumina-b library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"
