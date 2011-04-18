@api @json @uk10k @cancer @submission_template @submission @single-sign-on @new-api
Feature: Creating submissions from submission templates
  In order to get samples sequenced
  As a member of the UK10k project
  I need to be able to create submissions from templates
  And I need to be able to attach assets to these submissions
  And I need to be able to get a submission submitted

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing submission creation"
    And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the UUID for the submission template "Library creation - Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"

    Given the UUID for the request type "Library creation" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Paired end sequencing" is "99999999-1111-2222-3333-000000000001"

  @create @error
  Scenario Outline: Creating a new submission with missing initial information
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          <json>
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "<field>": [ "can't be blank" ]
        }
      }
      """

    Examples:
      | field   | json                                            |
      | study   | "project": "22222222-3333-4444-5555-000000000001" |
      | project | "study": "22222222-3333-4444-5555-000000000000"   |

  @create
  Scenario Outline: Creating a new submission 
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          <asset group details>
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },
          "assets": [],
          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    Examples:
      | asset group details            | asset group name                     |
      |                                | 11111111-2222-3333-4444-555555555555 |
      | "asset_group_name": "",          | 11111111-2222-3333-4444-555555555555 |
      | "asset_group_name": "new group", | new group                            |

  @create @asset_group 
  Scenario Outline: Creating a new submission with an existing asset group
    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"

    Given the sample tube named "Tube 1" exists
    And the sample tube "Tube 1" is in the asset group "Existing asset group"
    And the UUID for the sample tube "Tube 1" is "99999999-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000",
          <asset details>
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },
          "assets": [
            {
              "uuid": "99999999-1111-2222-3333-444444444444"
            }
          ],
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    Examples:
      | asset details                                       |
      | "asset_group_name": "Existing asset group"            |
      | "asset_group": "88888888-1111-2222-3333-000000000000" |

  @update @error 
  Scenario Outline: Attempting to change initial information after creating a submission
    Given I have an "active" study called "Altering the submission"
    And the UUID for the study "Altering the submission" is "22222222-3333-4444-5555-111111111111"

    Given I have a project called "Altering the submission"
    And the UUID for the project "Altering the submission" is "22222222-3333-4444-5555-111111111112"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "<field>": "<uuid>"
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "<field>": [ "cannot be changed" ]
        }
      }
      """

    Examples:
      | field   | uuid                                 |
      | study   | 22222222-3333-4444-5555-111111111111 |
      | project | 22222222-3333-4444-5555-111111111112 |

  @update @error @asset
  Scenario: Attempting to submit a submission that has no assets
    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "assets": [ "can't be blank" ]
        }
      }
      """

  @submit @error @asset
  Scenario: Attempting to submit a submission that has no assets where quotas are being enforced
    Given the project "Testing submission creation" has quotas and quotas are enforced

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "assets": [ "can't be blank" ]
        }
      }
      """
    And there should be no submissions to be processed

  @update @error @asset @asset_group
  Scenario: Attempts to modify assets for an existing asset group errors
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 10
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"
    And the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"
    And the sample tube "sampletube-1" is in the asset group "Existing asset group"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study       | 22222222-3333-4444-5555-000000000000 |
      | project     | 22222222-3333-4444-5555-000000000001 |
      | asset_group | 88888888-1111-2222-3333-000000000000 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "assets": [
            "33333333-4444-5555-6666-000000000002",
            "33333333-4444-5555-6666-000000000003"
          ]
        }
      }
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

  @update @error @asset
  Scenario Outline: Attempting to update the assets when the submission has been built
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | state            | <state>                                                                                                    |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "assets": [
            "33333333-4444-5555-6666-000000000002",
            "33333333-4444-5555-6666-000000000003"
          ]
        }
      }
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

    Examples:
      | state      |
      | pending    |
      | processing |
      | ready      |
      | failed     |

  @update @asset
  Scenario: Attaching assets to a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "assets": [
            "33333333-4444-5555-6666-000000000001",
            "33333333-4444-5555-6666-000000000002",
            "33333333-4444-5555-6666-000000000003"
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "assets": [
            {
              "uuid": "33333333-4444-5555-6666-000000000001"
            },
            {
              "uuid": "33333333-4444-5555-6666-000000000002"
            },
            {
              "uuid": "33333333-4444-5555-6666-000000000003"
            }
          ]
        }
      }
      """

  @update @asset
  Scenario Outline: Modifying the assets attached to a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |
      | assets  | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "assets": [<uuids>]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "assets": [<assets>]
        }
      }
      """

    Examples:
      | uuids                                                                          | assets                                                                                                 |
      |                                                                                |                                                                                                        |
      | "33333333-4444-5555-6666-000000000002"                                         | { "uuid": "33333333-4444-5555-6666-000000000002" }                                                     |
      | "33333333-4444-5555-6666-000000000002", "33333333-4444-5555-6666-000000000003" | { "uuid": "33333333-4444-5555-6666-000000000002" }, { "uuid": "33333333-4444-5555-6666-000000000003" } |

  @update @error
  Scenario Outline: Trying to update invalid request options
    Given I have a submission created with the following details based on the template "<template name>":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |
      | assets  | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "request_options": {
            <invalid options>
          }
        }
      }
      """

    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "request_options.<errors>
        }
      }
      """

    Scenarios: Checking the individual fields
      | template name                            | invalid options                             | errors                                                             |
      | Library Creation - Paired end sequencing | "read_length": "foo"                        | read_length": [ "is not a number", "is not included in the list" ] |
      | Library Creation - Paired end sequencing | "fragment_size_required": { "from": "foo" } | fragment_size_required.from": [ "is not a number" ]                |
      | Library Creation - Paired end sequencing | "fragment_size_required": { "to": "foo" }   | fragment_size_required.to": [ "is not a number" ]                  |
      | Library Creation - Paired end sequencing | "library_type": "One with books"            | library_type": [ "is not included in the list" ]                   |

    Scenarios: Where the read length does not match the list for the particular sequencing request
      | template name                                  | invalid options    | errors                                          |
      | Library Creation - Paired end sequencing       | "read_length": 100 | read_length": [ "is not included in the list" ] |
      | Library Creation - HiSeq Paired end sequencing | "read_length": 76  | read_length": [ "is not included in the list" ] |

  @update
  Scenario Outline: Updating the request options
    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study       | 22222222-3333-4444-5555-000000000000 |
      | project     | 22222222-3333-4444-5555-000000000001 |
      | assets      | 33333333-4444-5555-6666-000000000001 |
      | <attribute> | <value>                              |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """

    # We need to actually check that the underlying request options are correct because the JSON structure is different!
    Then the request options for the submission with UUID "11111111-2222-3333-4444-555555555555" should be:
      | read_length                 | 76        |
      | fragment_size_required_from | 100       |
      | fragment_size_required_to   | 200       |
      | library_type                | qPCR only |

    Scenarios: When the asset group is being created by the submission
      | attribute        | value           |
      | asset_group_name | new asset group |

    Scenarios: When the asset group is specified as part of the submission
      | attribute   | value                                |
      | asset_group | 88888888-1111-2222-3333-000000000000 |

  @update @error
  Scenario Outline: Attempting to update the request options when the submission has been built
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets          | 33333333-4444-5555-6666-000000000001                                                                       |
      | state           | <state>                                                                                                    |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "request_options": {
            "read_length": 100,
            "fragment_size_required": {
              "from": 1000,
              "to": 2000
            }
          }
        }
      }
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

    Examples:
      | state      |
      | pending    |
      | processing |
      | ready      |
      | failed     |

  @submit @error 
  Scenario Outline: Attempting to submit a submission that has been readied
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | state            | <state>                                                                                                    |

    When I GET the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON "submission.actions" should be exactly:
      """
      {
        "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
      }
      """

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """
    And there should be no submissions to be processed

    Examples:
      | state      |
      | pending    |
      | processing |
      | ready      |
      | failed     |

  # "TODO": This should be an outline for all quota failures but heck, need to just get this done ...
  @submit @error @project
  Scenario: Attempting to submit a submission that has a project that is not active
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given project "Testing submission creation" approval is "inactive"
    And the project "Testing submission creation" has quotas and quotas are enforced

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets          | 33333333-4444-5555-6666-000000000001                                                                       |

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "Project Testing submission creation is not approved" ]
      }
      """

  @submit @asset_group
  Scenario Outline: Submitting a submission where it was created with an asset group
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"
    And the sample tube "sampletube-1" is in the asset group "Existing asset group"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | <field>         | <value>                                                                                                    |

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "pending"
        }
      }
      """

    # Check that the assets are only in the original asset group
    Then the sample tube "sampletube-1" should only be in asset group "Existing asset group"

    Examples:
      | field            | value                                |
      | asset_group      | 88888888-1111-2222-3333-000000000000 |
      | asset_group_name | Existing asset group                 |

  @submit @asset_group
  Scenario Outline: Submitting a submission where the asset group is to be created
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | asset_group_name | <asset group name>                                                                                         |

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "pending"
        }
      }
      """

    # Check that the asset group really has been created!
    Then the asset group "<asset group name to check>" should only contain sample tube "sampletube-1"

    Examples: 
      | asset group name | asset group name to check            |
      |                  | 11111111-2222-3333-4444-555555555555 |
      | my group         | my group                             |

  @full-workflow @create @update @submit @read
  Scenario: Create submission, attach assets, and then submit it
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    # Retrieving the submission template ...
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "submissions": {
            "actions": {
              "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submissions"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Library creation - Paired end sequencing"
        }
      }
      """

    # Creating ...
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "state": "building",
          "assets": [],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {},
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """
    And the JSON should not contain "uuids_to_ids" within any element of "submission.request_types"

    # Attaching the assets and updating the details ...
    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "assets": [
            "33333333-4444-5555-6666-000000000001",
            "33333333-4444-5555-6666-000000000002",
            "33333333-4444-5555-6666-000000000003"
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "state": "building",
          "assets": [
            { "uuid": "33333333-4444-5555-6666-000000000001" },
            { "uuid": "33333333-4444-5555-6666-000000000002" },
            { "uuid": "33333333-4444-5555-6666-000000000003" }
          ],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          },
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    # Submitting the submission ...
    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "state": "pending",
          "assets": [
            { "uuid": "33333333-4444-5555-6666-000000000001" },
            { "uuid": "33333333-4444-5555-6666-000000000002" },
            { "uuid": "33333333-4444-5555-6666-000000000003" }
          ],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          },
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    # Check that the submission can be processed and creates the correct information in the DB
    Given all pending delayed jobs are processed
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready

    # Now reload the submission JSON to see that the state is correct ...
    Given the number of results returned by the API per page is 6
    When I GET the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "state": "ready",
          "assets": [
            { "uuid": "33333333-4444-5555-6666-000000000001" },
            { "uuid": "33333333-4444-5555-6666-000000000002" },
            { "uuid": "33333333-4444-5555-6666-000000000003" }
          ],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          },
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    # And now we'll check that the requests are correct too ...
    # ... there should be 3 library creation "requests": one per input asset (sample tube)
    # ... there should be 3 paired end sequencing "requests": one per output asset from the above requests
    When I GET the API path "/11111111-2222-3333-4444-555555555555/requests"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "last": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1",
          "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1",
          "first": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1"
        }, 
        "requests": [
          {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000001",
              "type": "sample_tubes"
            },
            "target_asset": null, 

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }, {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000002",
              "type": "sample_tubes"
            },
            "target_asset": null,

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }, {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000003",
              "type": "sample_tubes"
            },
            "target_asset": null,

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "study": {
              "uuid": "22222222-3333-4444-5555-000000000000"
            },
            "project": {
              "uuid": "22222222-3333-4444-5555-000000000001"
            },

            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }
        ]
      } 
      """

  @update @error @multiplier
  Scenario Outline: Invalid request for multiple runs of different requests within a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000 |
      | project          | 22222222-3333-4444-5555-000000000001 |
      | assets           | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "request_options": {
            "number_of_lanes": <number of lanes>
          }
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "request_options": [ <message> ]
        }
      }
      """

    Examples:
      | number of lanes | message                        |
      |  0              | "zero multiplier supplied"     |
      | -1              | "negative multiplier supplied" |

  @update @multiplier
  Scenario Outline: Requesting multiple runs of different requests within a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "request_options": {
            <json>

            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "request_options": {
            <json>

            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """

    # Now check that after it's been process the submission has the correct requests
    When the last submission has been submitted
    Given all pending delayed jobs are processed
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" should have 1 "Library creation" request
    And the submission with UUID "11111111-2222-3333-4444-555555555555" should have <sequencing requests> "Paired end sequencing" requests

    Examples:
      | json                | sequencing requests |
      |                     | 1                   |
      | "number_of_lanes": 1, | 1                   |
      | "number_of_lanes": 2, | 2                   |

