@api @json @single-sign-on @new-api @barcode-service
Feature: The top of the pulldown pipeline
  At the top of the pulldown pipeline a stock plate arrives and an initial pulldown plate is processed.
  "Processed" means that the plate is created from the stock plate, the entire contents of the stock
  plate is transferred to it, and the plate is started.  The act of starting the plate should change the
  state of the pulldown library creation requests it is the source asset for, but any other state changes
  should have no affect on these requests.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

      And the UUID for the transfer template "Transfer columns 1-12" is "22222222-3333-4444-5555-000000000001"
      And the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"
      And the UUID of the next plate creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next state change created will be "44444444-5555-6666-7777-000000000001"

  @authorised
  Scenario: Dealing with the initial plate in the WGS pipeline
    Given the UUID for the plate purpose "WGS stock DNA" is "11111111-2222-3333-4444-000000000001"
      And a "WGS stock DNA" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API" have unique samples

    Given the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Pulldown WGS - HiSeq Paired end sequencing"
      And the UUID for the last submission is "99998888-1111-2222-3333-444444444444"

    Given the UUID for the plate purpose "WGS Covaris" is "11111111-2222-3333-4444-000000000002"
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
          "state": "passed",
          "pools": {
            "99998888-1111-2222-3333-444444444444": {
              "wells": [
                "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A11", "A12",
                "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "B10", "B11", "B12",
                "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "C11", "C12",
                "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12",
                "E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10", "E11", "E12",
                "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
                "G1", "G2", "G3", "G4", "G5", "G6", "G7", "G8", "G9", "G10", "G11", "G12",
                "H1", "H2", "H3", "H4", "H5", "H6", "H7", "H8", "H9", "H10", "H11", "H12"
              ],
              "insert_size": {
                "from": 300,
                "to": 500
              },
              "library_type": {
                "name": "Standard"
              }
            }
          }
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
            "A3":  "A3",
            "A4":  "A4",
            "A5":  "A5",
            "A6":  "A6",
            "A7":  "A7",
            "A8":  "A8",
            "A9":  "A9",
            "A10": "A10",
            "A11": "A11",
            "A12": "A12",

            "B1":  "B1",
            "B2":  "B2",
            "B3":  "B3",
            "B4":  "B4",
            "B5":  "B5",
            "B6":  "B6",
            "B7":  "B7",
            "B8":  "B8",
            "B9":  "B9",
            "B10": "B10",
            "B11": "B11",
            "B12": "B12",

            "C1":  "C1",
            "C2":  "C2",
            "C3":  "C3",
            "C4":  "C4",
            "C5":  "C5",
            "C6":  "C6",
            "C7":  "C7",
            "C8":  "C8",
            "C9":  "C9",
            "C10": "C10",
            "C11": "C11",
            "C12": "C12",

            "D1":  "D1",
            "D2":  "D2",
            "D3":  "D3",
            "D4":  "D4",
            "D5":  "D5",
            "D6":  "D6",
            "D7":  "D7",
            "D8":  "D8",
            "D9":  "D9",
            "D10": "D10",
            "D11": "D11",
            "D12": "D12",

            "E1":  "E1",
            "E2":  "E2",
            "E3":  "E3",
            "E4":  "E4",
            "E5":  "E5",
            "E6":  "E6",
            "E7":  "E7",
            "E8":  "E8",
            "E9":  "E9",
            "E10": "E10",
            "E11": "E11",
            "E12": "E12",

            "F1":  "F1",
            "F2":  "F2",
            "F3":  "F3",
            "F4":  "F4",
            "F5":  "F5",
            "F6":  "F6",
            "F7":  "F7",
            "F8":  "F8",
            "F9":  "F9",
            "F10": "F10",
            "F11": "F11",
            "F12": "F12",

            "G1":  "G1",
            "G2":  "G2",
            "G3":  "G3",
            "G4":  "G4",
            "G5":  "G5",
            "G6":  "G6",
            "G7":  "G7",
            "G8":  "G8",
            "G9":  "G9",
            "G10": "G10",
            "G11": "G11",
            "G12": "G12",

            "H1":  "H1",
            "H2":  "H2",
            "H3":  "H3",
            "H4":  "H4",
            "H5":  "H5",
            "H6":  "H6",
            "H7":  "H7",
            "H8":  "H8",
            "H9":  "H9",
            "H10": "H10",
            "H11": "H11",
            "H12": "H12"
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
          "name": "Plate 1000002",
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
     And the state of all the pulldown library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"

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
     And the state of all the pulldown library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"

  @authorised
  Scenario Outline: Dealing with the initial plate in the pipeline
    Given the UUID for the plate purpose "<pipeline> stock DNA" is "11111111-2222-3333-4444-000000000001"
      And a "<pipeline> stock DNA" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API" have unique samples

    Given the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Pulldown <pipeline> - HiSeq Paired end sequencing"
      And the UUID for the last submission is "99998888-1111-2222-3333-444444444444"

    Given the UUID for the plate purpose "<plate purpose>" is "11111111-2222-3333-4444-000000000002"
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
          "state": "passed",
          "pools": {
            "99998888-1111-2222-3333-444444444444": {
              "wells": [
                "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A11", "A12",
                "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "B10", "B11", "B12",
                "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "C11", "C12",
                "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12",
                "E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10", "E11", "E12",
                "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
                "G1", "G2", "G3", "G4", "G5", "G6", "G7", "G8", "G9", "G10", "G11", "G12",
                "H1", "H2", "H3", "H4", "H5", "H6", "H7", "H8", "H9", "H10", "H11", "H12"
              ],
              "insert_size": {
                "from": 100,
                "to": 400
              },
              "library_type": {
                "name": "Agilent Pulldown"
                },
              "bait_library": {
                "name": "Human all exon 50MB",
                "target": {
                  "species": "Human"
                },
                "bait_library_type": "Standard",
                "supplier": {
                  "name": "Agilent"
                }
              }
            }
          }
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
            "A3":  "A3",
            "A4":  "A4",
            "A5":  "A5",
            "A6":  "A6",
            "A7":  "A7",
            "A8":  "A8",
            "A9":  "A9",
            "A10": "A10",
            "A11": "A11",
            "A12": "A12",

            "B1":  "B1",
            "B2":  "B2",
            "B3":  "B3",
            "B4":  "B4",
            "B5":  "B5",
            "B6":  "B6",
            "B7":  "B7",
            "B8":  "B8",
            "B9":  "B9",
            "B10": "B10",
            "B11": "B11",
            "B12": "B12",

            "C1":  "C1",
            "C2":  "C2",
            "C3":  "C3",
            "C4":  "C4",
            "C5":  "C5",
            "C6":  "C6",
            "C7":  "C7",
            "C8":  "C8",
            "C9":  "C9",
            "C10": "C10",
            "C11": "C11",
            "C12": "C12",

            "D1":  "D1",
            "D2":  "D2",
            "D3":  "D3",
            "D4":  "D4",
            "D5":  "D5",
            "D6":  "D6",
            "D7":  "D7",
            "D8":  "D8",
            "D9":  "D9",
            "D10": "D10",
            "D11": "D11",
            "D12": "D12",

            "E1":  "E1",
            "E2":  "E2",
            "E3":  "E3",
            "E4":  "E4",
            "E5":  "E5",
            "E6":  "E6",
            "E7":  "E7",
            "E8":  "E8",
            "E9":  "E9",
            "E10": "E10",
            "E11": "E11",
            "E12": "E12",

            "F1":  "F1",
            "F2":  "F2",
            "F3":  "F3",
            "F4":  "F4",
            "F5":  "F5",
            "F6":  "F6",
            "F7":  "F7",
            "F8":  "F8",
            "F9":  "F9",
            "F10": "F10",
            "F11": "F11",
            "F12": "F12",

            "G1":  "G1",
            "G2":  "G2",
            "G3":  "G3",
            "G4":  "G4",
            "G5":  "G5",
            "G6":  "G6",
            "G7":  "G7",
            "G8":  "G8",
            "G9":  "G9",
            "G10": "G10",
            "G11": "G11",
            "G12": "G12",

            "H1":  "H1",
            "H2":  "H2",
            "H3":  "H3",
            "H4":  "H4",
            "H5":  "H5",
            "H6":  "H6",
            "H7":  "H7",
            "H8":  "H8",
            "H9":  "H9",
            "H10": "H10",
            "H11": "H11",
            "H12": "H12"
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
          "name": "Plate 1000002",
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
     And the state of all the pulldown library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"

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
     And the state of all the pulldown library creation requests from the plate with UUID "00000000-1111-2222-3333-000000000001" should be "started"

    Scenarios:
      | pipeline | plate purpose |
      | SC       | SC Covaris    |
      | ISC      | ISC Covaris   |
