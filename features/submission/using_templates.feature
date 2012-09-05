@submission @submission_template @wip @old_submission
Feature: Creating submissions through the submission templates
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have a project called "Project testing submission templates"
    And project "Project testing submission templates" has enforced quotas
    And I have an active study called "Study testing submission templates"
    And the study "Study testing submission templates" has an asset group of 10 samples called "Asset group for submission templates"
    And the study "Study testing submission templates" has an asset group of 10 samples in "well" called "Asset group of wells for submission templates"
    And all of the wells are on a "Stock plate" plate

    Given all of this is happening at exactly "13-September-2010 09:30"

  # TODO: Scenario: The user does not manage any projects (flash[:error] = 'You do not manage any financial projects')
  # TODO: Scenario: Study unapproved (flash[:notice] = 'Your study is not yet approved')
  # TODO: Scenario: Project quotas not setup at all (QuotaException)
  # TODO: Scenario: Project is unapproved (QuotaException)
  # TODO: Scenario: Project inactive (QuotaException)
  # TODO: Scenario: Project unactionable (QuotaException)
  # TODO: Scenario: No samples in the asset group (QuotaException)
  # TODO: Scenario: Multiplex rquest with insufficient quota (QuotaException)

  Scenario: Requesting multiple sequencing requests, which are below quota
    Given the project "Project testing submission templates" has a "Single ended sequencing" quota of 50
    And the project "Project testing submission templates" has a "Library creation" quota of 10

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "Library creation - Single ended sequencing" from "Template"
    And I press "Next"

    When I fill in "Multiplier for step 2" with "5"
    And I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "76" from "Read length"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    And I create the order and submit the submission
    Then I should see "Submission successfully built"

  Scenario: Requesting multiple sequencing requests, which exceeds the quota
    Given the project "Project testing submission templates" has a "Single ended sequencing" quota of 49
    And the project "Project testing submission templates" has a "Library creation" quota of 10

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "Library creation - Single ended sequencing" from "Template"
    And I press "Next"

    When I fill in "Multiplier for step 2" with "5"
    And I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "76" from "Read length"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    And I press "Create Order"

    Then I should see "Insufficient quota for Single ended sequencing"

  Scenario Outline: The project does not have sufficient quotas for library creation
    Given the project "Project testing submission templates" has a "Single ended sequencing" quota of 999
    And the project "Project testing submission templates" has no "<library_type>" quota

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "<library_type> - Single ended sequencing" from "Template"
    And I press "Next"

    When I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "76" from "Read length"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    When I press "Create Order"

    Then I should see "Insufficient quota for <library_type>"

    Examples:
      |library_type                |
      |Library creation            |
      |Multiplexed library creation|
      |Pulldown library creation   |

  Scenario Outline: The project does not have sufficient quotas for sequencing type
    Given the project "Project testing submission templates" has a "Library creation" quota of 999
    And the project "Project testing submission templates" has no "<sequencing_type>" quota

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "Library creation - <sequencing_type>" from "Template"
    And I press "Next"

    When I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "<read length>" from "Read length"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    When I press "Create Order"

    Then I should see "Insufficient quota for <sequencing_type>"

    Examples:
      |sequencing_type            | read length |
      |Single ended sequencing    | 76          |
      |Paired end sequencing      | 76          |
      |HiSeq Paired end sequencing| 100         |

  Scenario Outline: Creating a valid submission for each type of library creation
    Given the project "Project testing submission templates" has a "<sequencing_type>" quota of 999
    And the project "Project testing submission templates" has a "<library_type>" quota of 999

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "<library_type> - <sequencing_type>" from "Template"
    And I press "Next"

    When I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "<read length>" from "Read length"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    And I create the order and submit the submission

    Then I should see "Submission successfully built"
    And I should see "Your submission is currently pending"
    And I should see "Submission created at: Monday 13 September, 2010 09:30"
    And I should see the submission request types of:
      |<library_type>   |
      |<sequencing_type>|

    Examples:
      |library_type                |sequencing_type             | read length |
      |Library creation            |Single ended sequencing     | 76          |
      |Library creation            |Paired end sequencing       | 76          |
      |Library creation            |HiSeq Paired end sequencing | 100         |
      |Multiplexed library creation|Single ended sequencing     | 76          |
      |Multiplexed library creation|Paired end sequencing       | 76          |
      |Multiplexed library creation|HiSeq Paired end sequencing | 100         |
      |Pulldown library creation   |Single ended sequencing     | 76          |
      |Pulldown library creation   |Paired end sequencing       | 76          |
      |Pulldown library creation   |HiSeq Paired end sequencing | 100         |

  Scenario: Creating a valid submission for microarray genotyping from an asset group
    Given the project "Project testing submission templates" has a "Cherrypick" quota of 999
    And the project "Project testing submission templates" has a "DNA QC" quota of 999
    And the project "Project testing submission templates" has a "Genotyping" quota of 999

    Given I am on the "Microarray genotyping" submission template selection page for study "Study testing submission templates"
    When I select "Microarray genotyping" from "Template"
    And I press "Next"

    # Microarray genotyping has no extra information attached to its request types
    Then I should not see "The following parameters will be applied to all the samples in the group"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"

    And I create the order and submit the submission

    Then I should see "Submission successfully built"
    And I should see "Your submission is currently pending"
    And I should see "Submission created at: Monday 13 September, 2010 09:30"
    And I should see the submission request types of:
      |Cherrypick|
      |DNA QC    |
      |Genotyping|

    # Ensure that the assets in the asset group are only in that asset group!
    Then the assets in the asset group "Asset group for submission templates" should only be in that group

  Scenario: Creating a valid submission for microarray genotyping a list of sample names
    Given the project "Project testing submission templates" has a "Cherrypick" quota of 999
    And the project "Project testing submission templates" has a "DNA QC" quota of 999
    And the project "Project testing submission templates" has a "Genotyping" quota of 999

    Given I am on the "Microarray genotyping" submission template selection page for study "Study testing submission templates"
    When I select "Microarray genotyping" from "Template"
    And I press "Next"

    # Microarray genotyping has no extra information attached to its request types
    Then I should not see "The following parameters will be applied to all the samples in the group"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I fill in "Enter a list of sample names" with the multiline text:
      """
      asset_group_of_wells_for_submission_templates_sample_1
      asset_group_of_wells_for_submission_templates_sample_2
      asset_group_of_wells_for_submission_templates_sample_3
      asset_group_of_wells_for_submission_templates_sample_4
      asset_group_of_wells_for_submission_templates_sample_5
      """

    And I create the order and submit the submission

    Then I should see "Submission successfully built"

    And I should see "Your submission is currently pending"
    And I should see "Submission created at: Monday 13 September, 2010 09:30"
    And I should see the submission request types of:
      |Cherrypick|
      |DNA QC    |
      |Genotyping|

    # Ensure that a new asset group has been created
    Then the asset group with the name from the last order UUID value contains the assets for the following samples:
      | asset_group_of_wells_for_submission_templates_sample_1 |
      | asset_group_of_wells_for_submission_templates_sample_2 |
      | asset_group_of_wells_for_submission_templates_sample_3 |
      | asset_group_of_wells_for_submission_templates_sample_4 |
      | asset_group_of_wells_for_submission_templates_sample_5 |

  Scenario Outline: The project does not have sufficient quotas for microarray sequencing step
    # Bit of a fiddle: set up all the quotas, then remove the one that we want to fail
    Given the project "Project testing submission templates" has a "Cherrypick" quota of 999
    And the project "Project testing submission templates" has a "DNA QC" quota of 999
    And the project "Project testing submission templates" has a "Genotyping" quota of 999
    And the project "Project testing submission templates" has no "<request_type>" quota

    Given I am on the "Microarray genotyping" submission template selection page for study "Study testing submission templates"
    When I select "Microarray genotyping" from "Template"
    And I press "Next"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    When I press "Create Order"

    Then I should see "Insufficient quota for <request_type>"

    Examples:
      |request_type|
      |Cherrypick  |
      |DNA QC      |
      |Genotyping  |

  Scenario Outline: Parameters can be applied to each sample based on the request types of the submission
    Given the project "Project testing submission templates" has a "<sequencing_type>" quota of 10
    And the project "Project testing submission templates" has a "<library_type>" quota of 10

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "<library_type> - <sequencing_type>" from "Template"
    And I press "Next"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    And I fill in "Fragment size required (to)" with "9999"
    And I fill in "Fragment size required (from)" with "1"
    And I select "Custom" from "Library type"
    And I select "<read_length>" from "Read length"
    And I create the order and submit the submission

    Then I should see "Submission successfully built"

    # Forces the submission to become a set of requests
    Given the last "pending" submission is made

    # Checking on the information for the requests
    When I follow "Back to study"
    And I follow "Asset groups"
    And I follow "Asset group for submission templates"
    And I follow "Asset group for submission templates, sample tube 1"

    # NOTE: Each request only shows the information that is relevant to it.
    # So, if "Library type" and "Read length" weren't options for "<library_type>", then they either would not
    # appear here or we'd see the default values, and we'd have to push through to the sequencing request to see them.
    When I follow "<library_type> request"
    Then I should see the following request information:
      | Read length:                   | <read_length> |
      | Fragment size required (from): | 1             |
      | Fragment size required (to):   | 9999          |
      | Library type:                  | Custom        |

    Examples:
      |library_type                |sequencing_type             |read_length|
      |Library creation            |Single ended sequencing     |108        |
      |Library creation            |Paired end sequencing       |108        |
      |Library creation            |HiSeq Paired end sequencing |50         |
      |Multiplexed library creation|Single ended sequencing     |108        |
      |Multiplexed library creation|Paired end sequencing       |108        |
      |Multiplexed library creation|HiSeq Paired end sequencing |100        |
      |Pulldown library creation   |Single ended sequencing     |108        |
      |Pulldown library creation   |Paired end sequencing       |108        |
      |Pulldown library creation   |HiSeq Paired end sequencing |50         |

  Scenario Outline: Selecting the appropriate sequencing read lengths
    Given the project "Project testing submission templates" has a "<sequencing type>" quota of 10
    And the project "Project testing submission templates" has a "Library creation" quota of 10

    Given I am on the "Next-gen sequencing" submission template selection page for study "Study testing submission templates"
    When I select "Library creation - <sequencing type>" from "Template"
    And I press "Next"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I select "Asset group for submission templates" from "Select a group to submit"
    And I fill in "Fragment size required (to)" with "9999"
    And I fill in "Fragment size required (from)" with "1"
    And I select "Custom" from "Library type"
    And I select "<read length>" from "Read length"
    And I create the order and submit the submission

    Then I should see "Submission successfully built"

    # Forces the submission to become a set of requests
    Given the last "pending" submission is made

    # Checking on the information for the requests
    When I follow "Back to study"
    And I follow "Asset groups"
    And I follow "Asset group for submission templates"
    And I follow "Asset group for submission templates, sample tube 1"

    When I follow "Library creation request"
    Then I should see the following request information:
      | Read length:                   | <read length> |
      | Fragment size required (from): | 1             |
      | Fragment size required (to):   | 9999          |
      | Library type:                  | Custom        |

    Examples:
      | sequencing type             | read length |
      | HiSeq Paired end sequencing | 50          |
      | HiSeq Paired end sequencing | 100         |
      | Single ended sequencing     | 37          |
      | Single ended sequencing     | 54          |
      | Single ended sequencing     | 76          |
      | Single ended sequencing     | 108         |
      | Paired end sequencing       | 37          |
      | Paired end sequencing       | 54          |
      | Paired end sequencing       | 76          |
      | Paired end sequencing       | 108         |
