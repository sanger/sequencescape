@api @json @object_service @single-sign-on @new-api
Feature: Access objects through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual resources through their UUID
  And I want to be able to perform other operations to individual resources
  And I want to be able to do all of this only knowing the UUID of a resource
  And I understand I will never be able to delete a resource through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given there are no samples

  @create @error
  Scenario: Creating an object but sending the wrong 'Content-Type'
    When I POST the following "text/plain" to the API path "/samples":
      """
      {
        "sample": {
          "sanger": {
            "name": "this_is_valid_json_but_wrong_content_type"
          }
        }
      }
      """
    Then the HTTP response should be "415 Invalid Request"
    And the JSON should be:
      """
      {
        "general": [ "the 'Content-Type' can only be 'application/json'" ]
      }
      """

  @paging
  Scenario: Retrieving the first page of objects when none exist
    When I GET the API path "/samples"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
        "actions": {
          "create": "http://www.example.com/api/1/samples",
          "read": "http://www.example.com/api/1/samples/1",
          "first": "http://www.example.com/api/1/samples/1",
          "last": "http://www.example.com/api/1/samples/1"
        },
        "size": 0,
        "samples": [ ]
      }
      """

  # "TODO": This should be an error but there is no way to support that at the moment
  @paging @error
  Scenario: Retrieving past the end of the pages
    When I GET the API path "/samples/2"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "past the end of the results" ]
      }
      """

  @paging @error
  Scenario: Retrieving before the start of the pages
    When I GET the API path "/samples/0"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "before the start of the results" ]
      }
      """

  @paging
  Scenario: Retrieving the page of objects when only one page exists
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/samples"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "create": "http://www.example.com/api/1/samples",
          "read": "http://www.example.com/api/1/samples/1",
          "first": "http://www.example.com/api/1/samples/1",
          "last": "http://www.example.com/api/1/samples/1"
        },
        "size": 1,
        "samples": [
          {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
              "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
            },

            "uuid": "00000000-1111-2222-3333-444444444444",
            "sanger": {
              "name": "testing_the_object_service"
            }
          }
        ]
      }
      """

  # "TODO[xxx]": order doesn't appear to be guaranteed when run with 'rake cucumber'
  @paging
  Scenario Outline: Retrieving the pages of objects
    Given 3 samples exist with the core name "testing_the_object_service" and IDs starting at 1
    And all samples have sequential UUIDs based on "11111111-2222-3333-4444"

    When I GET the API path "/samples/<page>"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "create": "http://www.example.com/api/1/samples",
          "first": "http://www.example.com/api/1/samples/1",
          "read": "http://www.example.com/api/1/samples/<page>",
          <extra paging>,
          "last": "http://www.example.com/api/1/samples/3"
        },
        "size": 3,
        "samples": [
          {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-<uuid>",
              "update": "http://www.example.com/api/1/11111111-2222-3333-4444-<uuid>"
            },

            "uuid": "11111111-2222-3333-4444-<uuid>",
            "sanger": {
              "name": "testing_the_object_service-<index>"
            }
          }
        ]
      }
      """

    Examples:
      | page | index | id | uuid         | extra paging                                                                                           |
      | 1    | 1     | 1  | 000000000001 | "next": "http://www.example.com/api/1/samples/2"                                                       |
      | 2    | 2     | 2  | 000000000002 | "next": "http://www.example.com/api/1/samples/3", "previous": "http://www.example.com/api/1/samples/1" |
      | 3    | 3     | 3  | 000000000003 | "previous": "http://www.example.com/api/1/samples/2"                                                   |

  @update @error
  Scenario: Updating the object associated with the UUID which gives an error
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "sanger": {
            "name": "weird green jelly like thing"
          }
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "sanger.name": [ "is read-only" ]
        }
      }
      """

  @update
  Scenario: Updating the object associated with the UUID
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "taxonomy": {
            "organism": "weird green jelly like thing"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "sanger": {
            "name": "testing_the_object_service"
          },
          "taxonomy": {
            "organism": "weird green jelly like thing"
          }
        }
      }
      """

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """

  @read @error
  Scenario: Reading the JSON for a UUID but 'Accept' header incorrect
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I GET the "text/plain" from the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "406 Unacceptable"
    And the JSON should be:
      """
      {
        "general": [ "the 'Accept' header can only be 'application/json'" ]
      }
      """

  @read
  Scenario Outline: Reading the JSON for a UUID
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    Given the sample "testing_the_object_service" is in <number of sample tubes> sample tubes with sequential IDs starting at 1
    And all sample tubes have sequential UUIDs based on "11111111-2222-3333-4444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "sanger": {
            "name": "testing_the_object_service"
          },

          "sample_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes"
            },
            "size": <number of sample tubes>
          }
        }
      }
      """

    Examples:
      | number of sample tubes |
      | 1                      |
      | 3                      |

  @action @error
  Scenario: Performing an unknown action upon an object
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    Given the sample "testing_the_object_service" is in 3 sample tubes with sequential IDs starting at 1
    And all sample tubes have sequential UUIDs based on "11111111-2222-3333-4444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444/flirby_wirby"
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should be:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

  @action @wip
  Scenario Outline: Performing an action upon an object
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    Given the sample "testing_the_object_service" is in 3 sample tubes with sequential IDs starting at 1
    And all sample tubes have sequential UUIDs based on "11111111-2222-3333-4444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444/<action path>"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "first": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes/1",
          "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes/1",
          "next": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes/2",
          "last": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes/3"
        },
        "sample_tubes": [
          {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            },

            "uuid": "11111111-2222-3333-4444-000000000001",
            "name": "testing_the_object_service sample tube 1",

            "aliquots": [
              {
                "sample": {
                  "actions": {
                    "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
                    "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
                  },

                  "uuid": "00000000-1111-2222-3333-444444444444",
                  "sanger": {
                    "name": "testing_the_object_service"
                  }
                }
              }
            ],

            "requests": {
              "actions": {
                "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001/requests"
              },
              "size": 0
            },
            "library_tubes": {
              "actions": {
                "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001/library_tubes"
              },
              "size": 0
            }
          }
        ]
      }
      """

    Examples:
      | action path    |
      | sample_tubes   |
      | sample_tubes/1 |

  @authorisation
  Scenario: The client is unauthorised so does not see the update action
    Given the "create" action on samples requires authorisation

    When I GET the API path "/samples"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
        "actions": {
          "first": "http://www.example.com/api/1/samples/1",
          "read": "http://www.example.com/api/1/samples/1",
          "last": "http://www.example.com/api/1/samples/1"
        },
        "size": 0,
        "samples": [ ]
      }
      """

  @authorisation
  Scenario: The client is authorised so does see the update action
    Given the "create" action on samples requires authorisation

    When I make an authorised GET the API path "/samples"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
        "actions": {
          "first": "http://www.example.com/api/1/samples/1",
          "read": "http://www.example.com/api/1/samples/1",
          "last": "http://www.example.com/api/1/samples/1",
          "create": "http://www.example.com/api/1/samples"
        },
        "size": 0,
        "samples": [ ]
      }
      """

  @authorisation @update
  Scenario: The client is authorised and attempts to perform update action
    Given the "update" action on a sample requires authorisation

    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "taxonomy": {
            "organism": "weird green jelly like thing"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "sanger": {
            "name": "testing_the_object_service"
          },
          "taxonomy": {
            "organism": "weird green jelly like thing"
          }
        }
      }
      """

  @authorisation @update @error
  Scenario: The client is unauthorised and attempts to perform update action
    Given the "update" action on a sample requires authorisation

    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "taxonomy": {
            "organism": "weird green jelly like thing"
          }
        }
      }
      """
    Then the HTTP response should be "501 Internal Error"
    And the JSON should be:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

  @authentication
  Scenario: Authentication checks are only made when they are unknown or not fresh.
    Given the sample named "testing_the_object_service" exists with ID 1
    And the UUID for the sample "testing_the_object_service" is "00000000-1111-2222-3333-444444444444"

    # First we are authenticating, everything should go well ...
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"

    # Now we are no longer recognised but the check should be fresh, so it should still work ...
    Given the WTSI single sign-on service does not recognise "I-am-authenticated"
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"

    # Finally we travel a bit in time, making our check stale, and then we should find an authentication error ...
    Given all of this is happening 2 hours from now
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "401 Unauthorised"
    And the JSON should be:
      """
      {
        "general": [ "the WTSISignOn cookie is invalid" ]
      }
      """
