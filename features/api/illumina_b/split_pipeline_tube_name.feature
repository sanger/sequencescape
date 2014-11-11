@api @json @single-sign-on @new-api @barcode-service
Feature: The bottom of the illumina_b htp pipeline
  At the bottom of the illumina_b pipeline individual wells of the final plate are transferred into the
  MX library tubes on a 1:1 basis.  Once an MX library tube has been processed the act of changing its
  state to "passed" (or "failed", or whatever really), causes the illumin_b library creation requests,
  that run from the wells of the stock plate to the tube, to also be updated.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "Cherrypicked" is "11111111-2222-3333-4444-000000000001"
      And the UUID for the purpose "Lib Pool" is "88888888-1111-2222-3333-000000000001"
      And the UUID for the transfer template "Transfer wells to specific tubes defined by submission" is "22222222-3333-4444-5555-000000000001"
      And the UUID for the transfer template "Transfer from tube to tube by submission" is "22222222-3333-4444-5555-000000000002"
      And the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"
      And the UUID of the next plate creation created will be "55555556-6666-7777-8888-000000000001"
      And the UUID of the next state change created will be "44444444-5555-6666-7777-000000000001"

    Given a "Cherrypicked" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And 4 wells on the plate "Testing the API" have unique samples

@authorised
  Scenario: Dealing with the MX library tube at the end of the pipeline
    Given the UUID of the next submission created will be "11111111-2222-3333-4444-000000000010"
      And "A1-B1" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Pooled PATH - HiSeq Paired end sequencing"
      And the UUID of the next submission created will be "11111111-2222-3333-4444-000000000020"
      And "C1-D1" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Pooled PATH - HiSeq Paired end sequencing"

    Given all submissions have been worked until the last plate of the "Illumina-B HTP" pipeline
      And all plates have sequential UUIDs based on "00000000-1111-2222-3333"
      And all multiplexed library tubes have sequential UUIDs based on "00000000-1111-2222-3333-9999"
      # And the plate "Plate 1000002" is "qc_completed"

    # Create the stock MX library tubes from the plate
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
          "targets": {
            "11111111-2222-3333-4444-000000000010": "98989898-1111-2222-3333-000000000001",
            "11111111-2222-3333-4444-000000000020": "98989898-1111-2222-3333-000000000002"
          }
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
                "barcode": { "ean13": "1221000002781" }
              }
            },
            "C1": {
              "uuid": "98989898-1111-2222-3333-000000000002",
              "stock_plate": {
                "barcode": { "ean13": "1221000002781" }
              }
            }
          }
        }
      }
      """

    Then the aliquots of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000001" should be the same as the wells "A1-B1" of the plate "Testing the API"
     And the name of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000001" should be "DN1000001M A1:B1"
     And the aliquots of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000002" should be the same as the wells "C1-D1" of the plate "Testing the API"
     And the name of the stock multiplexed library tube with UUID "98989898-1111-2222-3333-000000000002" should be "DN1000001M C1:D1"
