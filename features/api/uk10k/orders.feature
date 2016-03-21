@api @json @uk10k @cancer @order @submission @single-sign-on @new-api
Feature: Creating orders for UK10K
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Testing submission creation"
    And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the UUID for the order template "Illumina-C - Library creation - Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given the UUID for the request type "Illumina-C Library creation" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Illumina-C Paired end sequencing" is "99999999-1111-2222-3333-000000000001"

  @create @error
  Scenario Outline: Creating a new order with missing initial information
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
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
      | field   | json                                              |
      | study   | "project": "22222222-3333-4444-5555-000000000001" |
      | project | "study": "22222222-3333-4444-5555-000000000000"   |

  @create
  Scenario Outline: Creating a new order
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
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
        "order": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
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
              "name": "Illumina-C Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Illumina-C Paired end sequencing"
            }
          ]
        }
      }
      """

    Examples:
      | asset group details              | asset group name                     |
      |                                  | 11111111-2222-3333-4444-555555555555 |
      | "asset_group_name": "",          | 11111111-2222-3333-4444-555555555555 |
      | "asset_group_name": "new group", | new group                            |

  @create @asset_group
  Scenario Outline: Creating a new order with an existing asset group
    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"

    Given the sample tube named "Tube 1" exists
    And the sample tube "Tube 1" is in the asset group "Existing asset group"
    And the UUID for the sample tube "Tube 1" is "99999999-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
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
        "order": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
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
          ]
        }
      }
      """

    Examples:
      | asset details                                         |
      | "asset_group_name": "Existing asset group"            |
      | "asset_group": "88888888-1111-2222-3333-000000000000" |

  @update @error @multiplier
  Scenario Outline: Invalid request for multiple runs of different requests within an order
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000 |
      | project          | 22222222-3333-4444-5555-000000000001 |
      | assets           | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
  Scenario Outline: Requesting multiple runs of different requests within an order
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
        "order": {
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
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission
    When the last submission has been submitted
    Given all pending delayed jobs are processed
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" should have 1 "Illumina-C Library creation" request
    And the submission with UUID "11111111-2222-3333-4444-555555555555" should have <sequencing requests> "Illumina-C Paired end sequencing" requests

    Examples:
      | json                  | sequencing requests |
      |                       | 1                   |
      | "number_of_lanes": 1, | 1                   |
      | "number_of_lanes": 2, | 2                   |

  @update @asset
  Scenario: Attaching assets to an order
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
        "order": {
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
  Scenario Outline: Modifying the assets attached to an order
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |
      | assets  | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
          "assets": [<uuids>]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "order": {
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
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "<template name>":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |
      | assets  | 33333333-4444-5555-6666-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
      | template name                            | invalid options                             | errors                                              |
      | Library Creation - Paired end sequencing | "read_length": "foo"                        | read_length": ["is '0' should be 37, 54, 76 or 108"]  |
      | Library Creation - Paired end sequencing | "fragment_size_required": { "from": "foo" } | fragment_size_required.from": [ "is not a number" ] |
      | Library Creation - Paired end sequencing | "fragment_size_required": { "to": "foo" }   | fragment_size_required.to": [ "is not a number" ]   |
      | Library Creation - Paired end sequencing | "library_type": "One with books"            | library_type": ["is 'One with books' should be No PCR, High complexity and double size selected, Illumina cDNA protocol, Agilent Pulldown, Custom, High complexity, ChiP-seq, NlaIII gene expression, Standard, Long range, Small RNA, Double size selected, DpnII gene expression, TraDIS, qPCR only, Pre-quality controlled, DSN_RNAseq or RNA-seq dUTP"]    |

    Scenarios: Where the read length does not match the list for the particular sequencing request
      | template name                                  | invalid options    | errors                                               |
      | Library Creation - Paired end sequencing       | "read_length": 100 | read_length": ["is '100' should be 37, 54, 76 or 108"] |
      | Library Creation - HiSeq Paired end sequencing | "read_length": 76  | read_length": ["is '76' should be 50, 75 or 100"]      |

  @submit @error @project
  Scenario: Attempting to create an order that has a project that is not active
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given project "Testing submission creation" approval is "inactive"
    And project "Testing submission creation" has enforced quotas

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000",
          "assets": [ "33333333-4444-5555-6666-000000000001" ]
        }
      }
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "Project Testing submission creation is not approved" ]
      }
      """

  @update
  Scenario Outline: Updating the request options
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study       | 22222222-3333-4444-5555-000000000000 |
      | project     | 22222222-3333-4444-5555-000000000001 |
      | assets      | 33333333-4444-5555-6666-000000000001 |
      | <attribute> | <value>                              |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
        "order": {
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
    Then the request options for the order with UUID "11111111-2222-3333-4444-666666666666" should be:
      | read_length                 | 76        |
    Then the string request options for the order with UUID "11111111-2222-3333-4444-666666666666" should be:
      | library_type                | qPCR only |
      | fragment_size_required_from | 100       |
      | fragment_size_required_to   | 200       |

    Scenarios: When the asset group is being created by the order
      | attribute        | value           |
      | asset_group_name | new asset group |

    Scenarios: When the asset group is specified as part of the order
      | attribute   | value                                |
      | asset_group | 88888888-1111-2222-3333-000000000000 |

  @update @error @asset @asset_group
  Scenario: Attempts to modify assets for an existing asset group errors
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 10
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"
    And the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"
    And the sample tube "sampletube-1" is in the asset group "Existing asset group"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study       | 22222222-3333-4444-5555-000000000000 |
      | project     | 22222222-3333-4444-5555-000000000001 |
      | asset_group | 88888888-1111-2222-3333-000000000000 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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
  Scenario: Attempting to update the assets when the order has been added to a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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

  @update @error
  Scenario: Attempting to update the request options when the order has been added to a submission
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets          | 33333333-4444-5555-6666-000000000001                                                                       |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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

  @update @error
  Scenario Outline: Attempting to change initial information after creating an order
    Given I have an "active" study called "Altering the order"
    And the UUID for the study "Altering the order" is "22222222-3333-4444-5555-111111111111"

    Given I have a project called "Altering the order"
    And the UUID for the project "Altering the order" is "22222222-3333-4444-5555-111111111112"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
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

  @submit @asset_group
  Scenario Outline: Submitting a submission where the order was created with an asset group
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given the study "Testing submission creation" has an asset group called "Existing asset group"
    And the UUID for the asset group "Existing asset group" is "88888888-1111-2222-3333-000000000000"
    And the sample tube "sampletube-1" is in the asset group "Existing asset group"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | <field>         | <value>                                                                                                    |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

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
  Scenario Outline: Submitting a submission where the order has an asset group to be created
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
      | asset_group_name | <asset group name>                                                                                         |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

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

    # NOTE: The UUID used here comes from the order now, rather than the submission.
    Examples:
      | asset group name | asset group name to check            |
      |                  | 11111111-2222-3333-4444-666666666666 |
      | my group         | my group                             |
