@api @json @single-sign-on @new-api @barcode-service
Feature: The bottom of the illumina_b pipeline
  At the bottom of the illumina_b pipeline individual wells of the final plate are transferred into the
  MX library tubes on a 1:1 basis.  Once an MX library tube has been processed the act of changing its
  state to "passed" (or "failed", or whatever really), causes the illumin_b library creation requests,
  that run from the wells of the stock plate to the tube, to also be updated.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "ILB_STD_INPUT" is "11111111-2222-3333-4444-000000000001"
      And the UUID for the purpose "ILB_STD_STOCK" is "88888888-1111-2222-3333-000000000001"
      And the UUID for the transfer template "Transfer wells to specific tubes by submission" is "22222222-3333-4444-5555-000000000001"
      And the UUID for the transfer template "Transfer from tube to tube by submission" is "22222222-3333-4444-5555-000000000002"
      And the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"
      And the UUID of the next plate creation created will be "55555556-6666-7777-8888-000000000001"
      And the UUID of the next state change created will be "44444444-5555-6666-7777-000000000001"

    Given a "ILB_STD_INPUT" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API" have unique samples

  @authorised
  Scenario: Dealing with the MX library tube at the end of the pipeline
    Given "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"
      And "A7-H12" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"

    Given all submissions have been worked until the last plate of the "Illumina-B STD" pipeline
      And all plates have sequential UUIDs based on "00000000-1111-2222-3333"
      And all multiplexed library tubes have sequential UUIDs based on "00000000-1111-2222-3333-9999"

    # Find the last plate by barcode
    Then log "Find the last plate by barcode" for debugging
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
          "name": "Plate 1000002",
          "uuid": "00000000-1111-2222-3333-000000000002"
        }
      }
      """

    # Create the stock MX library tubes from the plate
    Then log "Create the stock MX library tubes from the plate" for debugging
    When I make an authorised POST with the following JSON to the API path "/tube_creations":
      """
      {
        "tube_creation": {
          "user": "99999999-8888-7777-6666-555555555555",
          "parent": "00000000-1111-2222-3333-000000000002",
          "child_purpose": "88888888-1111-2222-3333-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tube_creation": {
          "children": {
            "size": 2
          }
        }
      }
      """
     And all stock multiplexed library tubes have sequential UUIDs based on "98989898-1111-2222-3333"

    # Make the transfers from the plate to the appropriate stock MX library tubes
    Then log "Make the transfers from the plate to the appropriate stock MX library tubes" for debugging
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "00000000-1111-2222-3333-000000000002",
          "targets": [ "98989898-1111-2222-3333-000000000001", "98989898-1111-2222-3333-000000000002" ]
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "00000000-1111-2222-3333-000000000002"
          },
          "transfers": {
            "A1": {
              "uuid": "98989898-1111-2222-3333-000000000001",
              "stock_plate": {
                "barcode": { "ean13": "1221000001777" }
              }
            },
            "B1": {
              "uuid": "98989898-1111-2222-3333-000000000002",
              "stock_plate": {
                "barcode": { "ean13": "1221000001777" }
              }
            }
          }
        }
      }
      """

    Then the aliquots of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000002" should be the same as the wells "A7-H12" of the plate "Testing the API"
     And the name of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000002" should be "DN1000001M A7:H12"
     And the aliquots of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000001" should be the same as the wells "A1-H6" of the plate "Testing the API"
     And the name of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000001" should be "DN1000001M A1:H6"

    # Transfer from the stock MX tubes to the MX tubes
    Then log "Make the transfers from first stock tube to one MX tube" for debugging
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000002":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "98989898-1111-2222-3333-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "98989898-1111-2222-3333-000000000001"
          },
          "destination": {
            "uuid": "00000000-1111-2222-3333-999900000001"
          }
        }
      }
      """
    Then the aliquots of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be the same as the wells "A1-H6" of the plate "Testing the API"
     And the name of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "DN1000001M A1:H6"

    Then log "Make the transfers from second stock tube to one MX tube" for debugging
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000002":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "98989898-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "98989898-1111-2222-3333-000000000002"
          },
          "destination": {
            "uuid": "00000000-1111-2222-3333-999900000002"
          }
        }
      }
      """
    Then the aliquots of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be the same as the wells "A7-H12" of the plate "Testing the API"
     And the name of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "DN1000001M A7:H12"

    # Change the state of one tube to ensure it doesn't affect the other
    Then log "Change the state of one tube to ensure it doesn't affect the other" for debugging
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-999900000001",
          "target_state": "started"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "target": {
            "uuid": "00000000-1111-2222-3333-999900000001"
          },
          "target_state": "started",
          "previous_state": "pending"
        }
      }
      """

    Then the state of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "started"
     And the state of all the transfer requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "started"
     And the request type of all the transfer requests to the the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "Transfer"
     And the state of all the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "started"

    Then the state of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "pending"
     And the state of all the transfer requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "pending"
     And the state of all the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "started"

    # Now passing should adjust the state of the pulldown library creation request
    Then log "Now passing should adjust the state of the pulldown library creation request" for debugging
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-999900000001",
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
            "uuid": "00000000-1111-2222-3333-999900000001"
          },
          "target_state": "passed",
          "previous_state": "started"
        }
      }
      """

    Then the state of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"
     And the state of all the transfer requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"
     And the state of all the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"
     And all of the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be billed to their project


  #  @authorised
  #  Scenario Outline: Changing the tube state when requests are not "open"
  #    Given "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"
  #      And "A7-H12" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"
  #
  #    Given all submissions have been worked until the last plate of the "Illumina-B STD" pipeline
  #      And all plates have sequential UUIDs based on "00000000-1111-2222-3333"
  #      And all multiplexed library tubes have sequential UUIDs based on "00000000-1111-2222-3333-9999"
  #
  #    # Find the last plate by barcode
  #    Then log "Find the last plate by barcode" for debugging
  #    When I POST the following JSON to the API path "/33333333-4444-5555-6666-000000000001/first":
  #      """
  #      {
  #        "search": {
  #          "barcode": "1221000002781"
  #        }
  #      }
  #      """
  #    Then the HTTP response should be "301 Moved Permanently"
  #     And the JSON should match the following for the specified fields:
  #      """
  #      {
  #        "plate": {
  #          "name": "Plate 1000002",
  #          "uuid": "00000000-1111-2222-3333-000000000002"
  #        }
  #      }
  #      """
  #
  #    # Make the transfers from the plate to the appropriate MX library tubes
  #    Then log "Make the transfers from the plate to the appropriate MX library tubes" for debugging
  #    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
  #      """
  #      {
  #        "transfer": {
  #          "user": "99999999-8888-7777-6666-555555555555",
  #          "source": "00000000-1111-2222-3333-000000000002"
  #        }
  #      }
  #      """
  #    Then the HTTP response should be "201 Created"
  #     And the JSON should match the following for the specified fields:
  #      """
  #      {
  #        "transfer": {
  #          "source": {
  #            "uuid": "00000000-1111-2222-3333-000000000002"
  #          },
  #          "transfers": {
  #            "A1": { "uuid": "00000000-1111-2222-3333-999900000001" },
  #            "B1": { "uuid": "00000000-1111-2222-3333-999900000002" }
  #          }
  #        }
  #      }
  #      """
  #
  #    Then the aliquots of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be the same as the wells "A1-H6" of the plate "Testing the API"
  #     And the name of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "DN1000001M A1:H6"
  #     And the aliquots of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be the same as the wells "A7-H12" of the plate "Testing the API"
  #     And the name of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "DN1000001M A7:H12"
  #
  #    # Change the state of the requests to the tube so that they are in the initial state
  #    Given the state of all the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" is "<state>"
  #    Then log "Change the state of one tube to ensure it doesn't affect the other" for debugging
  #    When I make an authorised POST with the following JSON to the API path "/state_changes":
  #      """
  #      {
  #        "state_change": {
  #          "user": "99999999-8888-7777-6666-555555555555",
  #          "target": "00000000-1111-2222-3333-999900000001",
  #          "target_state": "passed"
  #        }
  #      }
  #      """
  #    Then the HTTP response should be "201 Created"
  #     And the JSON should match the following for the specified fields:
  #      """
  #      {
  #        "state_change": {
  #          "target": {
  #            "uuid": "00000000-1111-2222-3333-999900000001"
  #          },
  #          "target_state": "passed",
  #          "previous_state": "pending"
  #        }
  #      }
  #      """
  #
  #    Then the state of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"
  #     And the state of all the transfer requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"
  #     And the state of all the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "<state>"
  #     And all of the illumina-b library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should not have billing
  #
  #    Scenarios:
  #      | state     | 
  #      | cancelled | 
  #      | passed    | 
  #      | failed    | 
