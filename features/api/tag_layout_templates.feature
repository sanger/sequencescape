@api @json @tag_layout_template @single-sign-on @new-api
Feature: Access tag layout templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual tag layout templates through their UUID
  And I want to be able to perform other operations to individual tag layout templates
  And I want to be able to do all of this only knowing the UUID of a tag layout template
  And I understand I will never be able to delete a tag layout template through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | ACTG  |
        | 2     | GTCA  |

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test tag layout",
          "direction": "column",
          "walking_by": "wells in pools",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "ACTG",
              "2": "GTCA"
            }
          }
        }
      }
      """

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout from a tag layout template
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled in columns to the plate "Testing the tagging"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA |
      | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC |
      | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT |
      | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG |
      | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC |
      | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG |
      | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT |
      | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout from an inverted tag layout template
    Given the plate barcode webservice returns "1000001..1000002"

    Given the inverted tag layout template "Test inverted tag layout" exists
      And the UUID for the tag layout template "Test inverted tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test inverted tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test inverted tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled in columns to the plate "Testing the tagging"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "inverse column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG |
      | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT |
      | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG |
      | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC |
      | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG |
      | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT |
      | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC |
      | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout from a tag layout template which ignores pools
    Given the plate barcode webservice returns "1000001..1000002"

    Given the entire plate tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" has tags 1..96
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled in columns to the plate "Testing the tagging"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",
          "walking_by": "wells of plate",

          "tag_group": {
            "name": "Tag group 1"
          }
        }
      }
      """

    Then the tags assigned to the plate "Testing the tagging" should be 1..96 for wells "A1-H12"

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout from a tag layout template where wells have been failed
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo    |
        | 1     | TAGCTTGT |
        | 2     | CGATGTTT |
        | 3     | GCCAATGT |
        | 4     | ACAGTGGT |
        | 5     | ATCACGTT |
        | 6     | GATCAGCG |
        | 7     | CAGATCTG |
        | 8     | TTAGGCAT |
        | 9     | GGCTACAG |
        | 10    | CTTGTACT |
        | 11    | ACTTGATG |
        | 12    | TGACCACT |
        | 13    | TGGTTGTT |
        | 14    | TCTCGGTT |
        | 15    | TAAGCGTT |
        | 16    | TCCGTCTT |
        | 17    | TGTACCTT |
        | 18    | TTCTGTGT |
        | 19    | TCTGCTGT |
        | 20    | TTGGAGGT |
        | 21    | TCGAGCGT |
        | 22    | TGATACGT |
        | 23    | TGCATAGT |
        | 24    | TTGACTCT |
        | 25    | TGCGATCT |
        | 26    | TTCCTGCT |
        | 27    | TAGTGACT |
        | 28    | TACAGGAT |
        | 29    | TCCTCAAT |
        | 30    | TGTGGTTG |
        | 31    | TAGTCTTG |
        | 32    | TTCCATTG |
        | 33    | TCGAAGTG |
        | 34    | TAACGCTG |
        | 35    | TTGGTATG |
        | 36    | TGAACTGG |
        | 37    | TACTTCGG |
        | 38    | TCTCACGG |
        | 39    | TCAGGAGG |
        | 40    | TAAGTTCG |
        | 41    | TCCAGTCG |
        | 42    | TGTATGCG |
        | 43    | TCATTGAG |
        | 44    | TGGCTCAG |
        | 45    | TATGCCAG |
        | 46    | TCAGATTC |
        | 47    | TACTAGTC |
        | 48    | TTCAGCTC |
        | 49    | TGTCTATC |
        | 50    | TATGTGGC |
        | 51    | TTACTCGC |
        | 52    | TCGTTAGC |
        | 53    | TACCGAGC |
        | 54    | TGTTCTCC |
        | 55    | TTCGCACC |
        | 56    | TTGCGTAC |
        | 57    | TCTACGAC |
        | 58    | TGACAGAC |
        | 59    | TAGAACAC |
        | 60    | TCATCCTA |
        | 61    | TGCTGATA |
        | 62    | TAGACGGA |
        | 63    | TGTGAAGA |
        | 64    | TCTCTTCA |
        | 65    | TTGTTCCA |
        | 66    | TGAAGCCA |
        | 67    | TACCACCA |
        | 68    | TGCGTGAA |
        | 69    | GGTGAGTT |
        | 70    | GATCTCTT |
        | 71    | GTGTCCTT |
        | 72    | GACGGATT |
        | 73    | GCAACATT |
        | 74    | GGTCGTGT |
        | 75    | GAATCTGT |
        | 76    | GTACATCT |
        | 77    | GAGGTGCT |
        | 78    | GCATGGCT |
        | 79    | GTTAGCCT |
        | 80    | GTCGCTAT |
        | 81    | GGAATGAT |
        | 82    | GAGCCAAT |
        | 83    | GCTCCTTG |
        | 84    | GTAAGGTG |
        | 85    | GAGGATGG |
        | 86    | GTTGTCGG |
        | 87    | GGATTAGG |
        | 88    | GATAGAGG |
        | 89    | GTGTGTCG |
        | 90    | GCAATCCG |
        | 91    | GACCTTAG |
        | 92    | GCCTGTTC |
        | 93    | GCACTGTC |
        | 94    | GCTAACTC |
        | 95    | GATTCATC |
        | 96    | GTCTTGGC |

      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 96
      And "F11-F12" of the plate "Testing the tagging" have been failed
      And "G12-G12" of the plate "Testing the tagging" have been failed

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1":  "TAGCTTGT",
              "2":  "CGATGTTT",
              "3":  "GCCAATGT",
              "4":  "ACAGTGGT",
              "5":  "ATCACGTT",
              "6":  "GATCAGCG",
              "7":  "CAGATCTG",
              "8":  "TTAGGCAT",
              "9":  "GGCTACAG",
              "10": "CTTGTACT",
              "11": "ACTTGATG",
              "12": "TGACCACT",
              "13": "TGGTTGTT",
              "14": "TCTCGGTT",
              "15": "TAAGCGTT",
              "16": "TCCGTCTT",
              "17": "TGTACCTT",
              "18": "TTCTGTGT",
              "19": "TCTGCTGT",
              "20": "TTGGAGGT",
              "21": "TCGAGCGT",
              "22": "TGATACGT",
              "23": "TGCATAGT",
              "24": "TTGACTCT",
              "25": "TGCGATCT",
              "26": "TTCCTGCT",
              "27": "TAGTGACT",
              "28": "TACAGGAT",
              "29": "TCCTCAAT",
              "30": "TGTGGTTG",
              "31": "TAGTCTTG",
              "32": "TTCCATTG",
              "33": "TCGAAGTG",
              "34": "TAACGCTG",
              "35": "TTGGTATG",
              "36": "TGAACTGG",
              "37": "TACTTCGG",
              "38": "TCTCACGG",
              "39": "TCAGGAGG",
              "40": "TAAGTTCG",
              "41": "TCCAGTCG",
              "42": "TGTATGCG",
              "43": "TCATTGAG",
              "44": "TGGCTCAG",
              "45": "TATGCCAG",
              "46": "TCAGATTC",
              "47": "TACTAGTC",
              "48": "TTCAGCTC",
              "49": "TGTCTATC",
              "50": "TATGTGGC",
              "51": "TTACTCGC",
              "52": "TCGTTAGC",
              "53": "TACCGAGC",
              "54": "TGTTCTCC",
              "55": "TTCGCACC",
              "56": "TTGCGTAC",
              "57": "TCTACGAC",
              "58": "TGACAGAC",
              "59": "TAGAACAC",
              "60": "TCATCCTA",
              "61": "TGCTGATA",
              "62": "TAGACGGA",
              "63": "TGTGAAGA",
              "64": "TCTCTTCA",
              "65": "TTGTTCCA",
              "66": "TGAAGCCA",
              "67": "TACCACCA",
              "68": "TGCGTGAA",
              "69": "GGTGAGTT",
              "70": "GATCTCTT",
              "71": "GTGTCCTT",
              "72": "GACGGATT",
              "73": "GCAACATT",
              "74": "GGTCGTGT",
              "75": "GAATCTGT",
              "76": "GTACATCT",
              "77": "GAGGTGCT",
              "78": "GCATGGCT",
              "79": "GTTAGCCT",
              "80": "GTCGCTAT",
              "81": "GGAATGAT",
              "82": "GAGCCAAT",
              "83": "GCTCCTTG",
              "84": "GTAAGGTG",
              "85": "GAGGATGG",
              "86": "GTTGTCGG",
              "87": "GGATTAGG",
              "88": "GATAGAGG",
              "89": "GTGTGTCG",
              "90": "GCAATCCG",
              "91": "GACCTTAG",
              "92": "GCCTGTTC",
              "93": "GCACTGTC",
              "94": "GCTAACTC",
              "95": "GATTCATC",
              "96": "GTCTTGGC"
            }
          }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAGCTTGT | GGCTACAG | TGTACCTT | TGCGATCT | TCGAAGTG | TCCAGTCG | TGTCTATC | TCTACGAC | TTGTTCCA | GCAACATT | GGAATGAT | GTGTGTCG |
      | CGATGTTT | CTTGTACT | TTCTGTGT | TTCCTGCT | TAACGCTG | TGTATGCG | TATGTGGC | TGACAGAC | TGAAGCCA | GGTCGTGT | GAGCCAAT | GCAATCCG |
      | GCCAATGT | ACTTGATG | TCTGCTGT | TAGTGACT | TTGGTATG | TCATTGAG | TTACTCGC | TAGAACAC | TACCACCA | GAATCTGT | GCTCCTTG | GACCTTAG |
      | ACAGTGGT | TGACCACT | TTGGAGGT | TACAGGAT | TGAACTGG | TGGCTCAG | TCGTTAGC | TCATCCTA | TGCGTGAA | GTACATCT | GTAAGGTG | GCCTGTTC |
      | ATCACGTT | TGGTTGTT | TCGAGCGT | TCCTCAAT | TACTTCGG | TATGCCAG | TACCGAGC | TGCTGATA | GGTGAGTT | GAGGTGCT | GAGGATGG | GCACTGTC |
      | GATCAGCG | TCTCGGTT | TGATACGT | TGTGGTTG | TCTCACGG | TCAGATTC | TGTTCTCC | TAGACGGA | GATCTCTT | GCATGGCT |          |          |
      | CAGATCTG | TAAGCGTT | TGCATAGT | TAGTCTTG | TCAGGAGG | TACTAGTC | TTCGCACC | TGTGAAGA | GTGTCCTT | GTTAGCCT | GGATTAGG |          |
      | TTAGGCAT | TCCGTCTT | TTGACTCT | TTCCATTG | TAAGTTCG | TTCAGCTC | TTGCGTAC | TCTCTTCA | GACGGATT | GTCGCTAT | GATAGAGG | GTCTTGGC |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout with substitutions from a tag layout template
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled in columns to the plate "Testing the tagging"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001",
          "substitutions": {
            "8": "7",
            "7": "8"
          }
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          },
          "substitutions": {
            "8": "7",
            "7": "8"
          }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA |
      | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC |
      | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT |
      | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG |
      | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC |
      | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG |
      | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG |
      | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout where the pools are factors of the number of rows on the plate
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
        | 9     | GAGA  |
        | 10    | CACA  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 8, 4, 8, 4, 8, 4, 8, 4, 8, 4, 8, 4, 8, 4, 8, 4

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          },
          "substitutions": { }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA |
      | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC |
      | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT | TTTT |
      | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG | GGGG |
      | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC |
      | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG |
      | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT |
      | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout where the pools are awkwardly sized and cause overlaps
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
        | 9     | GAGA  |
        | 10    | CACA  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 8, 2, 10, 4, 8, 2, 10, 4, 8, 2, 10, 4, 8, 8, 8

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",
          "direction": "column",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          },
          "substitutions": { }
        }
      }
      """

    Then the tag layout on the plate "Testing the tagging" should be:
      | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA | AAAA |
      | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC | CCCC |
      | TTTT | TTTT | GAGA | TTTT | TTTT | GAGA | TTTT | TTTT | GAGA | TTTT | TTTT | TTTT |
      | GGGG | GGGG | CACA | GGGG | GGGG | CACA | GGGG | GGGG | CACA | GGGG | GGGG | GGGG |
      | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC | AACC |
      | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG | TTGG |
      | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT | AATT |
      | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG | CCGG |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout of an entire plate using 96 tags
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" has 96 tags
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 96

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG1 | TAG9  | TAG17 | TAG25 | TAG33 | TAG41 | TAG49 | TAG57 | TAG65 | TAG73 | TAG81 | TAG89 |
      | TAG2 | TAG10 | TAG18 | TAG26 | TAG34 | TAG42 | TAG50 | TAG58 | TAG66 | TAG74 | TAG82 | TAG90 |
      | TAG3 | TAG11 | TAG19 | TAG27 | TAG35 | TAG43 | TAG51 | TAG59 | TAG67 | TAG75 | TAG83 | TAG91 |
      | TAG4 | TAG12 | TAG20 | TAG28 | TAG36 | TAG44 | TAG52 | TAG60 | TAG68 | TAG76 | TAG84 | TAG92 |
      | TAG5 | TAG13 | TAG21 | TAG29 | TAG37 | TAG45 | TAG53 | TAG61 | TAG69 | TAG77 | TAG85 | TAG93 |
      | TAG6 | TAG14 | TAG22 | TAG30 | TAG38 | TAG46 | TAG54 | TAG62 | TAG70 | TAG78 | TAG86 | TAG94 |
      | TAG7 | TAG15 | TAG23 | TAG31 | TAG39 | TAG47 | TAG55 | TAG63 | TAG71 | TAG79 | TAG87 | TAG95 |
      | TAG8 | TAG16 | TAG24 | TAG32 | TAG40 | TAG48 | TAG56 | TAG64 | TAG72 | TAG80 | TAG88 | TAG96 |

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout where one of the wells is empty
    Given the plate barcode webservice returns "1000001..1000002"

    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" has 96 tags
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000002"
      And all wells on the plate "Testing the API" have unique samples
      And H12 on the plate "Testing the API" is empty

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And the wells for the plate "Testing the API" have been pooled to the plate "Testing the tagging" according to the pooling strategy 95

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Then the tag layout on the plate "Testing the tagging" should be:
      | TAG1 | TAG9  | TAG17 | TAG25 | TAG33 | TAG41 | TAG49 | TAG57 | TAG65 | TAG73 | TAG81 | TAG89 |
      | TAG2 | TAG10 | TAG18 | TAG26 | TAG34 | TAG42 | TAG50 | TAG58 | TAG66 | TAG74 | TAG82 | TAG90 |
      | TAG3 | TAG11 | TAG19 | TAG27 | TAG35 | TAG43 | TAG51 | TAG59 | TAG67 | TAG75 | TAG83 | TAG91 |
      | TAG4 | TAG12 | TAG20 | TAG28 | TAG36 | TAG44 | TAG52 | TAG60 | TAG68 | TAG76 | TAG84 | TAG92 |
      | TAG5 | TAG13 | TAG21 | TAG29 | TAG37 | TAG45 | TAG53 | TAG61 | TAG69 | TAG77 | TAG85 | TAG93 |
      | TAG6 | TAG14 | TAG22 | TAG30 | TAG38 | TAG46 | TAG54 | TAG62 | TAG70 | TAG78 | TAG86 | TAG94 |
      | TAG7 | TAG15 | TAG23 | TAG31 | TAG39 | TAG47 | TAG55 | TAG63 | TAG71 | TAG79 | TAG87 | TAG95 |
      | TAG8 | TAG16 | TAG24 | TAG32 | TAG40 | TAG48 | TAG56 | TAG64 | TAG72 | TAG80 | TAG88 |       |
