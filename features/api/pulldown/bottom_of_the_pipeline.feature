@api @json @single-sign-on @new-api @barcode-service
Feature: The bottom of the pulldown pipeline
  At the bottom of the pulldown pipeline individual wells of the final plate are transfered into the
  MX library tubes on a 1:1 basis.  Once an MX library tube has been processed the act of changing its
  state to "passed" (or "failed", or whatever really), causes the pulldown library creation requests,
  that run from the wells of the stock plate to the tube, to also be updated.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "Pulldown stock plate" is "11111111-2222-3333-4444-000000000001"
      And the UUID for the transfer template "Transfer wells to MX library tubes by submission" is "22222222-3333-4444-5555-000000000001"
      And the UUID for the search "Find asset by barcode" is "33333333-4444-5555-6666-000000000001"
      And the UUID of the next plate creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next state change created will be "44444444-5555-6666-7777-000000000001"

    Given a "Pulldown stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  @authorised
  Scenario Outline: Dealing with the MX library tube at the end of the pipeline
    Given "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "<pipeline> - HiSeq Paired end sequencing"
      And "A7-H12" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "<pipeline> - HiSeq Paired end sequencing"

    Given all submissions have been worked until the last plate of the "<pipeline>" pipeline
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

    # Make the transfers from the plate to the appropriate MX library tubes
    Then log "Make the transfers from the plate to the appropriate MX library tubes" for debugging
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
      """
      {
        "transfer": {
          "source": "00000000-1111-2222-3333-000000000002"
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
          "destinations": [
            { "uuid": "00000000-1111-2222-3333-999900000001" },
            { "uuid": "00000000-1111-2222-3333-999900000002" }
          ],
          "transfers": [ "A1", "B1" ]
        }
      }
      """

    # Change the state of one tube to ensure it doesn't affect the other
    Then log "Change the state of one tube to ensure it doesn't affect the other" for debugging
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
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
     And the state of all the pulldown library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "pending"

    Then the state of the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "pending"
     And the state of all the transfer requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "pending"
     And the state of all the pulldown library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000002" should be "pending"

    # Now passing should adjust the state of the pulldown library creation request
    Then log "Now passing should adjust the state of the pulldown library creation request" for debugging
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
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
     And the state of all the pulldown library creation requests to the multiplexed library tube with UUID "00000000-1111-2222-3333-999900000001" should be "passed"

    Scenarios:
      | pipeline     |
      | Pulldown WGS |
      | Pulldown SC  |
      | Pulldown ISC |
