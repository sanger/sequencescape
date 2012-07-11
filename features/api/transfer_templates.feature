@api @json @transfer_template @single-sign-on @new-api
Feature: Access transfer templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual transfer templates through their UUID
  And I want to be able to perform other operations to individual transfer templates
  And I want to be able to do all of this only knowing the UUID of a transfer template
  And I understand I will never be able to delete a transfer template through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON of a transfer template
    Given the transfer template called "Test transfers" exists
     And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test transfers",
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

  @read @authenticated
  Scenario: Making an authenticated read for the JSON of a transfer template
    Given the transfer template called "Test transfers" exists
     And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    When I make an authorised GET for the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "preview": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/preview"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test transfers",
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

  @transfer @create @authenticated
  Scenario: Creating a transfer from a transfer template
    Given the transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And a destination transfer plate called "Destination plate" exists
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

    Then the transfers from the plate "Source plate" to the plate "Destination plate" should be:
      | source | destination |
      | A1     | A1          |
      | B1     | B1          |

  @transfer @create @authenticated
  Scenario: Creating a transfer from a transfer template where some source wells are empty
    Given the transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And the wells "A1-A1" on the plate "Source plate" are empty
      And a destination transfer plate called "Destination plate" exists
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "B1": "B1"
          }
        }
      }
      """

    Then the transfers from the plate "Source plate" to the plate "Destination plate" should be:
      | source | destination |
      | B1     | B1          |

  @transfer @create @authenticated
  Scenario: Creating a transfer from a transfer template by pools
    Given the pooling transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the plate "Source plate" is a "Stock plate"
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And a destination transfer plate called "Destination plate" exists as a child of "Source plate"
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"
      And transfers between "Stock plate" and "Child plate purpose" plates are done by "Transfer" requests

    Given "A1-B1" of the plate "Source plate" have been submitted to "Pulldown WGS - HiSeq Paired end sequencing"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "A1": "A1",
            "B1": "A1"
          }
        }
      }
      """

    Then the transfers from the plate "Source plate" to the plate "Destination plate" should be:
      | source | destination |
      | A1     | A1          |
      | B1     | A1          |

  @transfer @create @authenticated
  Scenario: Creating a transfer from a transfer template by pools where some wells are empty
    Given the pooling transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the plate "Source plate" is a "Stock plate"
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And the wells "A1-A1" on the plate "Source plate" are empty
      And a destination transfer plate called "Destination plate" exists as a child of "Source plate"
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"
      And transfers between "Stock plate" and "Child plate purpose" plates are done by "Transfer" requests

    Given "A1-B1" of the plate "Source plate" have been submitted to "Pulldown WGS - HiSeq Paired end sequencing"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "B1": "A1"
          }
        }
      }
      """

    Then the transfers from the plate "Source plate" to the plate "Destination plate" should be:
      | source | destination |
      | B1     | A1          |

  @transfer @preview @authenticated
  Scenario: Previewing a transfer from a transfer template
    Given the transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And a destination transfer plate called "Destination plate" exists
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444/preview":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

