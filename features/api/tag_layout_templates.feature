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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag  |
      | A1   | AAAA |
      | B1   | CCCC |
      | C1   | TTTT |
      | D1   | GGGG |
      | E1   | AACC |
      | F1   | TTGG |
      | G1   | AATT |
      | H1   | CCGG |
      | A2   | AAAA |
      | B2   | CCCC |
      | C2   | TTTT |
      | D2   | GGGG |
      | E2   | AACC |
      | F2   | TTGG |
      | G2   | AATT |
      | H2   | CCGG |
      | A3   | AAAA |
      | B3   | CCCC |
      | C3   | TTTT |
      | D3   | GGGG |
      | E3   | AACC |
      | F3   | TTGG |
      | G3   | AATT |
      | H3   | CCGG |
      | A4   | AAAA |
      | B4   | CCCC |
      | C4   | TTTT |
      | D4   | GGGG |
      | E4   | AACC |
      | F4   | TTGG |
      | G4   | AATT |
      | H4   | CCGG |
      | A5   | AAAA |
      | B5   | CCCC |
      | C5   | TTTT |
      | D5   | GGGG |
      | E5   | AACC |
      | F5   | TTGG |
      | G5   | AATT |
      | H5   | CCGG |
      | A6   | AAAA |
      | B6   | CCCC |
      | C6   | TTTT |
      | D6   | GGGG |
      | E6   | AACC |
      | F6   | TTGG |
      | G6   | AATT |
      | H6   | CCGG |
      | A7   | AAAA |
      | B7   | CCCC |
      | C7   | TTTT |
      | D7   | GGGG |
      | E7   | AACC |
      | F7   | TTGG |
      | G7   | AATT |
      | H7   | CCGG |
      | A8   | AAAA |
      | B8   | CCCC |
      | C8   | TTTT |
      | D8   | GGGG |
      | E8   | AACC |
      | F8   | TTGG |
      | G8   | AATT |
      | H8   | CCGG |
      | A9   | AAAA |
      | B9   | CCCC |
      | C9   | TTTT |
      | D9   | GGGG |
      | E9   | AACC |
      | F9   | TTGG |
      | G9   | AATT |
      | H9   | CCGG |
      | A10  | AAAA |
      | B10  | CCCC |
      | C10  | TTTT |
      | D10  | GGGG |
      | E10  | AACC |
      | F10  | TTGG |
      | G10  | AATT |
      | H10  | CCGG |
      | A11  | AAAA |
      | B11  | CCCC |
      | C11  | TTTT |
      | D11  | GGGG |
      | E11  | AACC |
      | F11  | TTGG |
      | G11  | AATT |
      | H11  | CCGG |
      | A12  | AAAA |
      | B12  | CCCC |
      | C12  | TTTT |
      | D12  | GGGG |
      | E12  | AACC |
      | F12  | TTGG |
      | G12  | AATT |
      | H12  | CCGG |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag      |
      | A1   | TAGCTTGT |
      | B1   | CGATGTTT |
      | C1   | GCCAATGT |
      | D1   | ACAGTGGT |
      | E1   | ATCACGTT |
      | F1   | GATCAGCG |
      | G1   | CAGATCTG |
      | H1   | TTAGGCAT |
      | A2   | GGCTACAG |
      | B2   | CTTGTACT |
      | C2   | ACTTGATG |
      | D2   | TGACCACT |
      | E2   | TGGTTGTT |
      | F2   | TCTCGGTT |
      | G2   | TAAGCGTT |
      | H2   | TCCGTCTT |
      | A3   | TGTACCTT |
      | B3   | TTCTGTGT |
      | C3   | TCTGCTGT |
      | D3   | TTGGAGGT |
      | E3   | TCGAGCGT |
      | F3   | TGATACGT |
      | G3   | TGCATAGT |
      | H3   | TTGACTCT |
      | A4   | TGCGATCT |
      | B4   | TTCCTGCT |
      | C4   | TAGTGACT |
      | D4   | TACAGGAT |
      | E4   | TCCTCAAT |
      | F4   | TGTGGTTG |
      | G4   | TAGTCTTG |
      | H4   | TTCCATTG |
      | A5   | TCGAAGTG |
      | B5   | TAACGCTG |
      | C5   | TTGGTATG |
      | D5   | TGAACTGG |
      | E5   | TACTTCGG |
      | F5   | TCTCACGG |
      | G5   | TCAGGAGG |
      | H5   | TAAGTTCG |
      | A6   | TCCAGTCG |
      | B6   | TGTATGCG |
      | C6   | TCATTGAG |
      | D6   | TGGCTCAG |
      | E6   | TATGCCAG |
      | F6   | TCAGATTC |
      | G6   | TACTAGTC |
      | H6   | TTCAGCTC |
      | A7   | TGTCTATC |
      | B7   | TATGTGGC |
      | C7   | TTACTCGC |
      | D7   | TCGTTAGC |
      | E7   | TACCGAGC |
      | F7   | TGTTCTCC |
      | G7   | TTCGCACC |
      | H7   | TTGCGTAC |
      | A8   | TCTACGAC |
      | B8   | TGACAGAC |
      | C8   | TAGAACAC |
      | D8   | TCATCCTA |
      | E8   | TGCTGATA |
      | F8   | TAGACGGA |
      | G8   | TGTGAAGA |
      | H8   | TCTCTTCA |
      | A9   | TTGTTCCA |
      | B9   | TGAAGCCA |
      | C9   | TACCACCA |
      | D9   | TGCGTGAA |
      | E9   | GGTGAGTT |
      | F9   | GATCTCTT |
      | G9   | GTGTCCTT |
      | H9   | GACGGATT |
      | A10  | GCAACATT |
      | B10  | GGTCGTGT |
      | C10  | GAATCTGT |
      | D10  | GTACATCT |
      | E10  | GAGGTGCT |
      | F10  | GCATGGCT |
      | G10  | GTTAGCCT |
      | H10  | GTCGCTAT |
      | A11  | GGAATGAT |
      | B11  | GAGCCAAT |
      | C11  | GCTCCTTG |
      | D11  | GTAAGGTG |
      | E11  | GAGGATGG |
      | F11  |          |
      | G11  | GGATTAGG |
      | H11  | GATAGAGG |
      | A12  | GTGTGTCG |
      | B12  | GCAATCCG |
      | C12  | GACCTTAG |
      | D12  | GCCTGTTC |
      | E12  | GCACTGTC |
      | F12  |          |
      | G12  |          |
      | H12  | GTCTTGGC |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag  |
      | A1   | AAAA |
      | B1   | CCCC |
      | C1   | TTTT |
      | D1   | GGGG |
      | E1   | AACC |
      | F1   | TTGG |
      | G1   | CCGG |
      | H1   | AATT |
      | A2   | AAAA |
      | B2   | CCCC |
      | C2   | TTTT |
      | D2   | GGGG |
      | E2   | AACC |
      | F2   | TTGG |
      | G2   | CCGG |
      | H2   | AATT |
      | A3   | AAAA |
      | B3   | CCCC |
      | C3   | TTTT |
      | D3   | GGGG |
      | E3   | AACC |
      | F3   | TTGG |
      | G3   | CCGG |
      | H3   | AATT |
      | A4   | AAAA |
      | B4   | CCCC |
      | C4   | TTTT |
      | D4   | GGGG |
      | E4   | AACC |
      | F4   | TTGG |
      | G4   | CCGG |
      | H4   | AATT |
      | A5   | AAAA |
      | B5   | CCCC |
      | C5   | TTTT |
      | D5   | GGGG |
      | E5   | AACC |
      | F5   | TTGG |
      | G5   | CCGG |
      | H5   | AATT |
      | A6   | AAAA |
      | B6   | CCCC |
      | C6   | TTTT |
      | D6   | GGGG |
      | E6   | AACC |
      | F6   | TTGG |
      | G6   | CCGG |
      | H6   | AATT |
      | A7   | AAAA |
      | B7   | CCCC |
      | C7   | TTTT |
      | D7   | GGGG |
      | E7   | AACC |
      | F7   | TTGG |
      | G7   | CCGG |
      | H7   | AATT |
      | A8   | AAAA |
      | B8   | CCCC |
      | C8   | TTTT |
      | D8   | GGGG |
      | E8   | AACC |
      | F8   | TTGG |
      | G8   | CCGG |
      | H8   | AATT |
      | A9   | AAAA |
      | B9   | CCCC |
      | C9   | TTTT |
      | D9   | GGGG |
      | E9   | AACC |
      | F9   | TTGG |
      | G9   | CCGG |
      | H9   | AATT |
      | A10  | AAAA |
      | B10  | CCCC |
      | C10  | TTTT |
      | D10  | GGGG |
      | E10  | AACC |
      | F10  | TTGG |
      | G10  | CCGG |
      | H10  | AATT |
      | A11  | AAAA |
      | B11  | CCCC |
      | C11  | TTTT |
      | D11  | GGGG |
      | E11  | AACC |
      | F11  | TTGG |
      | G11  | CCGG |
      | H11  | AATT |
      | A12  | AAAA |
      | B12  | CCCC |
      | C12  | TTTT |
      | D12  | GGGG |
      | E12  | AACC |
      | F12  | TTGG |
      | G12  | CCGG |
      | H12  | AATT |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag  |
      | A1   | AAAA |
      | B1   | CCCC |
      | C1   | TTTT |
      | D1   | GGGG |
      | E1   | AACC |
      | F1   | TTGG |
      | G1   | AATT |
      | H1   | CCGG |
      | A2   | AAAA |
      | B2   | CCCC |
      | C2   | TTTT |
      | D2   | GGGG |
      | E2   | AACC |
      | F2   | TTGG |
      | G2   | AATT |
      | H2   | CCGG |
      | A3   | AAAA |
      | B3   | CCCC |
      | C3   | TTTT |
      | D3   | GGGG |
      | E3   | AACC |
      | F3   | TTGG |
      | G3   | AATT |
      | H3   | CCGG |
      | A4   | AAAA |
      | B4   | CCCC |
      | C4   | TTTT |
      | D4   | GGGG |
      | E4   | AACC |
      | F4   | TTGG |
      | G4   | AATT |
      | H4   | CCGG |
      | A5   | AAAA |
      | B5   | CCCC |
      | C5   | TTTT |
      | D5   | GGGG |
      | E5   | AACC |
      | F5   | TTGG |
      | G5   | AATT |
      | H5   | CCGG |
      | A6   | AAAA |
      | B6   | CCCC |
      | C6   | TTTT |
      | D6   | GGGG |
      | E6   | AACC |
      | F6   | TTGG |
      | G6   | AATT |
      | H6   | CCGG |
      | A7   | AAAA |
      | B7   | CCCC |
      | C7   | TTTT |
      | D7   | GGGG |
      | E7   | AACC |
      | F7   | TTGG |
      | G7   | AATT |
      | H7   | CCGG |
      | A8   | AAAA |
      | B8   | CCCC |
      | C8   | TTTT |
      | D8   | GGGG |
      | E8   | AACC |
      | F8   | TTGG |
      | G8   | AATT |
      | H8   | CCGG |
      | A9   | AAAA |
      | B9   | CCCC |
      | C9   | TTTT |
      | D9   | GGGG |
      | E9   | AACC |
      | F9   | TTGG |
      | G9   | AATT |
      | H9   | CCGG |
      | A10  | AAAA |
      | B10  | CCCC |
      | C10  | TTTT |
      | D10  | GGGG |
      | E10  | AACC |
      | F10  | TTGG |
      | G10  | AATT |
      | H10  | CCGG |
      | A11  | AAAA |
      | B11  | CCCC |
      | C11  | TTTT |
      | D11  | GGGG |
      | E11  | AACC |
      | F11  | TTGG |
      | G11  | AATT |
      | H11  | CCGG |
      | A12  | AAAA |
      | B12  | CCCC |
      | C12  | TTTT |
      | D12  | GGGG |
      | E12  | AACC |
      | F12  | TTGG |
      | G12  | AATT |
      | H12  | CCGG |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag  |
      | A1   | AAAA |
      | B1   | CCCC |
      | C1   | TTTT |
      | D1   | GGGG |
      | E1   | AACC |
      | F1   | TTGG |
      | G1   | AATT |
      | H1   | CCGG |
      | A2   | AAAA |
      | B2   | CCCC |
      | C2   | TTTT |
      | D2   | GGGG |
      | E2   | AACC |
      | F2   | TTGG |
      | G2   | AATT |
      | H2   | CCGG |
      | A3   | AAAA |
      | B3   | CCCC |
      | C3   | GAGA |
      | D3   | CACA |
      | E3   | AACC |
      | F3   | TTGG |
      | G3   | AATT |
      | H3   | CCGG |
      | A4   | AAAA |
      | B4   | CCCC |
      | C4   | TTTT |
      | D4   | GGGG |
      | E4   | AACC |
      | F4   | TTGG |
      | G4   | AATT |
      | H4   | CCGG |
      | A5   | AAAA |
      | B5   | CCCC |
      | C5   | TTTT |
      | D5   | GGGG |
      | E5   | AACC |
      | F5   | TTGG |
      | G5   | AATT |
      | H5   | CCGG |
      | A6   | AAAA |
      | B6   | CCCC |
      | C6   | GAGA |
      | D6   | CACA |
      | E6   | AACC |
      | F6   | TTGG |
      | G6   | AATT |
      | H6   | CCGG |
      | A7   | AAAA |
      | B7   | CCCC |
      | C7   | TTTT |
      | D7   | GGGG |
      | E7   | AACC |
      | F7   | TTGG |
      | G7   | AATT |
      | H7   | CCGG |
      | A8   | AAAA |
      | B8   | CCCC |
      | C8   | TTTT |
      | D8   | GGGG |
      | E8   | AACC |
      | F8   | TTGG |
      | G8   | AATT |
      | H8   | CCGG |
      | A9   | AAAA |
      | B9   | CCCC |
      | C9   | GAGA |
      | D9   | CACA |
      | E9   | AACC |
      | F9   | TTGG |
      | G9   | AATT |
      | H9   | CCGG |
      | A10  | AAAA |
      | B10  | CCCC |
      | C10  | TTTT |
      | D10  | GGGG |
      | E10  | AACC |
      | F10  | TTGG |
      | G10  | AATT |
      | H10  | CCGG |
      | A11  | AAAA |
      | B11  | CCCC |
      | C11  | TTTT |
      | D11  | GGGG |
      | E11  | AACC |
      | F11  | TTGG |
      | G11  | AATT |
      | H11  | CCGG |
      | A12  | AAAA |
      | B12  | CCCC |
      | C12  | TTTT |
      | D12  | GGGG |
      | E12  | AACC |
      | F12  | TTGG |
      | G12  | AATT |
      | H12  | CCGG |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag   |
      | A1   | TAG1  |
      | B1   | TAG2  |
      | C1   | TAG3  |
      | D1   | TAG4  |
      | E1   | TAG5  |
      | F1   | TAG6  |
      | G1   | TAG7  |
      | H1   | TAG8  |
      | A2   | TAG9  |
      | B2   | TAG10 |
      | C2   | TAG11 |
      | D2   | TAG12 |
      | E2   | TAG13 |
      | F2   | TAG14 |
      | G2   | TAG15 |
      | H2   | TAG16 |
      | A3   | TAG17 |
      | B3   | TAG18 |
      | C3   | TAG19 |
      | D3   | TAG20 |
      | E3   | TAG21 |
      | F3   | TAG22 |
      | G3   | TAG23 |
      | H3   | TAG24 |
      | A4   | TAG25 |
      | B4   | TAG26 |
      | C4   | TAG27 |
      | D4   | TAG28 |
      | E4   | TAG29 |
      | F4   | TAG30 |
      | G4   | TAG31 |
      | H4   | TAG32 |
      | A5   | TAG33 |
      | B5   | TAG34 |
      | C5   | TAG35 |
      | D5   | TAG36 |
      | E5   | TAG37 |
      | F5   | TAG38 |
      | G5   | TAG39 |
      | H5   | TAG40 |
      | A6   | TAG41 |
      | B6   | TAG42 |
      | C6   | TAG43 |
      | D6   | TAG44 |
      | E6   | TAG45 |
      | F6   | TAG46 |
      | G6   | TAG47 |
      | H6   | TAG48 |
      | A7   | TAG49 |
      | B7   | TAG50 |
      | C7   | TAG51 |
      | D7   | TAG52 |
      | E7   | TAG53 |
      | F7   | TAG54 |
      | G7   | TAG55 |
      | H7   | TAG56 |
      | A8   | TAG57 |
      | B8   | TAG58 |
      | C8   | TAG59 |
      | D8   | TAG60 |
      | E8   | TAG61 |
      | F8   | TAG62 |
      | G8   | TAG63 |
      | H8   | TAG64 |
      | A9   | TAG65 |
      | B9   | TAG66 |
      | C9   | TAG67 |
      | D9   | TAG68 |
      | E9   | TAG69 |
      | F9   | TAG70 |
      | G9   | TAG71 |
      | H9   | TAG72 |
      | A10  | TAG73 |
      | B10  | TAG74 |
      | C10  | TAG75 |
      | D10  | TAG76 |
      | E10  | TAG77 |
      | F10  | TAG78 |
      | G10  | TAG79 |
      | H10  | TAG80 |
      | A11  | TAG81 |
      | B11  | TAG82 |
      | C11  | TAG83 |
      | D11  | TAG84 |
      | E11  | TAG85 |
      | F11  | TAG86 |
      | G11  | TAG87 |
      | H11  | TAG88 |
      | A12  | TAG89 |
      | B12  | TAG90 |
      | C12  | TAG91 |
      | D12  | TAG92 |
      | E12  | TAG93 |
      | F12  | TAG94 |
      | G12  | TAG95 |
      | H12  | TAG96 |

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

    Then the tags assigned to the plate "Testing the tagging" should be:
      | well | tag   |
      | A1   | TAG1  |
      | B1   | TAG2  |
      | C1   | TAG3  |
      | D1   | TAG4  |
      | E1   | TAG5  |
      | F1   | TAG6  |
      | G1   | TAG7  |
      | H1   | TAG8  |
      | A2   | TAG9  |
      | B2   | TAG10 |
      | C2   | TAG11 |
      | D2   | TAG12 |
      | E2   | TAG13 |
      | F2   | TAG14 |
      | G2   | TAG15 |
      | H2   | TAG16 |
      | A3   | TAG17 |
      | B3   | TAG18 |
      | C3   | TAG19 |
      | D3   | TAG20 |
      | E3   | TAG21 |
      | F3   | TAG22 |
      | G3   | TAG23 |
      | H3   | TAG24 |
      | A4   | TAG25 |
      | B4   | TAG26 |
      | C4   | TAG27 |
      | D4   | TAG28 |
      | E4   | TAG29 |
      | F4   | TAG30 |
      | G4   | TAG31 |
      | H4   | TAG32 |
      | A5   | TAG33 |
      | B5   | TAG34 |
      | C5   | TAG35 |
      | D5   | TAG36 |
      | E5   | TAG37 |
      | F5   | TAG38 |
      | G5   | TAG39 |
      | H5   | TAG40 |
      | A6   | TAG41 |
      | B6   | TAG42 |
      | C6   | TAG43 |
      | D6   | TAG44 |
      | E6   | TAG45 |
      | F6   | TAG46 |
      | G6   | TAG47 |
      | H6   | TAG48 |
      | A7   | TAG49 |
      | B7   | TAG50 |
      | C7   | TAG51 |
      | D7   | TAG52 |
      | E7   | TAG53 |
      | F7   | TAG54 |
      | G7   | TAG55 |
      | H7   | TAG56 |
      | A8   | TAG57 |
      | B8   | TAG58 |
      | C8   | TAG59 |
      | D8   | TAG60 |
      | E8   | TAG61 |
      | F8   | TAG62 |
      | G8   | TAG63 |
      | H8   | TAG64 |
      | A9   | TAG65 |
      | B9   | TAG66 |
      | C9   | TAG67 |
      | D9   | TAG68 |
      | E9   | TAG69 |
      | F9   | TAG70 |
      | G9   | TAG71 |
      | H9   | TAG72 |
      | A10  | TAG73 |
      | B10  | TAG74 |
      | C10  | TAG75 |
      | D10  | TAG76 |
      | E10  | TAG77 |
      | F10  | TAG78 |
      | G10  | TAG79 |
      | H10  | TAG80 |
      | A11  | TAG81 |
      | B11  | TAG82 |
      | C11  | TAG83 |
      | D11  | TAG84 |
      | E11  | TAG85 |
      | F11  | TAG86 |
      | G11  | TAG87 |
      | H11  | TAG88 |
      | A12  | TAG89 |
      | B12  | TAG90 |
      | C12  | TAG91 |
      | D12  | TAG92 |
      | E12  | TAG93 |
      | F12  | TAG94 |
      | G12  | TAG95 |
      | H12  |       |
