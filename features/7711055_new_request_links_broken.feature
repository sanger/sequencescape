@asset @request @javascript
Feature: Creating new requests from an asset
  Background:
    Given a sample tube called "Sample tube for testing new request" exists
      And a properly created library tube called "Library tube for testing new request" exists
      And a properly created multiplexed library tube called "Multiplexed library tube for testing new request" exists
      And an improperly created multiplexed library tube called "Faulty Multiplexed library tube for testing new request" exists
      And I have an "active" study called "Study testing new request"
      And I have an "approved" project called "Project testing new request"

    Given I am logged in as "John Smith"

  @administrator
  Scenario Outline: List of all assets
    Given user "John Smith" is an administrator
      And the asset "Sample tube for testing new request" belongs to study "Study testing new request"

    Given I am on the assets page for the study "Study testing new request" in the "<workflow>" workflow
     When I follow "New request" within "[id='asset_sample_tube_for_testing_new_request']"
     Then I should be on the new request page for "Sample tube for testing new request"
      And "Study testing new request" should be selected from "Study"

    Scenarios:
      | workflow              |
      | Next-gen sequencing   |
      | Microarray genotyping |

  @study @administrator
  Scenario Outline: New request link from an individual asset page, via a study, as an administrator
    Given user "John Smith" is an administrator

    Given I am on the <page> for asset "<asset type> for testing new request" within "Study testing new request"
     When I follow "<link to follow>"
     Then I should be on the new request page for "<asset type> for testing new request"
      And "Study testing new request" should be selected from "Study"

    @sample_tube
    Scenarios:
      | asset type  | link to follow        | page                                       |
      | Sample tube | Request a new library | show page                                  |
      | Sample tube | Request a new library | "Next-gen sequencing" workflow show page   |
      | Sample tube | Request a new library | "Microarray genotyping" workflow show page |

    @library_tube
    Scenarios:
      | asset type   | link to follow                | page                                     |
      | Library tube | Request additional sequencing | show page                                |
      | Library tube | Request additional sequencing | "Next-gen sequencing" workflow show page |

    @multiplexed_library_tube
    Scenarios:
      | asset type                      | link to follow                | page                                     |
      | Multiplexed library tube        | Request additional sequencing | show page                                |
      | Faulty Multiplexed library tube | Request additional sequencing | show page                                |
      | Multiplexed library tube        | Request additional sequencing | "Next-gen sequencing" workflow show page |

  @manager
  Scenario Outline: Request more sequencing as the manager of a study for the asset
    Given user "John Smith" is a manager of "Study testing new request"
      And the asset "<asset type> for testing new request" belongs to study "Study testing new request"

    Given I am on the <page> for asset "<asset type> for testing new request" within "Study testing new request"
     When I follow "Request additional sequencing"
     Then I should be on the new request page for "<asset type> for testing new request"

    @library_tube
    Scenarios:
      | asset type   | page                                     |
      | Library tube | show page                                |
      | Library tube | "Next-gen sequencing" workflow show page |

    @multiplexed_library_tube
    Scenarios:
      | asset type               | page                                     |
      | Multiplexed library tube | show page                                |
      | Multiplexed library tube | "Next-gen sequencing" workflow show page |

  @library_tube
  Scenario: The link to request more sequencing should not be visible to a mere mortal
    Given I am on the show page for asset "Library tube for testing new request" within "Study testing new request"
     Then I should not see "Request additional sequencing"

  @administrator
  Scenario Outline: New request link from individual asset page as an administrator
    Given user "John Smith" is an administrator

    Given I am on the show page for asset "<asset type> for testing new request"
     When I follow "<link to follow>"
     Then I should be on the new request page for "<asset type> for testing new request"

    @sample_tube @library_tube @multiplexed_library_tube
    Scenarios:
      | asset type               | link to follow                |
      | Sample tube              | Request a new library         |
      | Library tube             | Request additional sequencing |
      | Multiplexed library tube | Request additional sequencing |

  @sample_tube @foo
  Scenario Outline: Requesting an additional library from a sample tube
    Given user "John Smith" is a manager of "Study testing new request"
      And the asset "Sample tube for testing new request" belongs to study "Study testing new request"

    Given I am on the new request page for "Sample tube for testing new request"

    When I select "<request type>" from "Request type"
     And I fill in the request fields with sensible values for "<request type>"
     And I select "Study testing new request" from "Study"
     And I select "Project testing new request" from "Project"
     And I press "Create"
    Then I should see "Created request"

    Given all pending delayed jobs are processed
     Then the source asset of the last "<request type>" request should be a "Sample tube"

    Scenarios:
      | request type                               |
      | Illumina-C Library creation                |
      | Multiplexed library creation               |
      | Pulldown library creation                  |

  @foo
  Scenario Outline: Requesting more sequencing of an library
    Given user "John Smith" is a manager of "Study testing new request"
      And the asset "<asset type> for testing new request" belongs to study "Study testing new request"

    Given I am on the new request page for "<asset type> for testing new request"

     When I select "<request type>" from "Request type"
     Then the "Fragment size required (from)" field should contain "<fragment size required from>"
      And the "Fragment size required (to)" field should contain "<fragment size required to>"
     And I fill in the request fields with sensible values for "<request type>"
     And I select "Study testing new request" from "Study"
     And I select "Project testing new request" from "Project"
     And I press "Create"
    Then I should see "Created request"

    Given all pending delayed jobs are processed
     Then the source asset of the last "<request type>" request should be a "<asset type>"

    @library_tube
    Scenarios:
      | asset type   | request type                              | fragment size required from | fragment size required to |
      | Library tube | Illumina-B Single ended sequencing        | 100                         | 200                       |
      | Library tube | Illumina-B Single ended hi seq sequencing | 100                         | 200                       |
      | Library tube | Illumina-B Paired end sequencing          | 100                         | 200                       |
      | Library tube | Illumina-B HiSeq Paired end sequencing    | 100                         | 200                       |

    @multiplexed_library_tube
    Scenarios:
      | asset type               | request type                              | fragment size required from | fragment size required to |
      | Multiplexed library tube | Illumina-B Single ended sequencing        | 150                         | 400                       |
      | Multiplexed library tube | Illumina-B Single ended hi seq sequencing | 150                         | 400                       |
      | Multiplexed library tube | Illumina-B Paired end sequencing          | 150                         | 400                       |
      | Multiplexed library tube | Illumina-B HiSeq Paired end sequencing    | 150                         | 400                       |
