@study @accession_number
Feature: Check Study accession xml is valid
  Scenario Outline: A study with a ebi-valid type should use this type
    Given a study named "My study" exists
    Given the study "My study" is a "<study_type>" study
    When I request XML for the show accession page for study named "My study"
    Then the value of the "existing_study_type" attribute of the XML element "//STUDY_TYPE" should be "<study_type>"

    Examples:
      | study_type|
      | Synthetic Genomics|
      | Forensic or Paleo-genomics|
      | Gene Regulation Study|
      | Cancer Genomics|
      | Whole Genome Sequencing|
      | Metagenomics|
      | Transcriptome Analysis|
      | Population Genomics|
      | Resequencing|
      | Epigenetics|

  Scenario Outline: A study with an other ebi type should use other type
    Given a study named "My study" exists
    Given the study "My study" is a "<study_type>" study
    When I request XML for the show accession page for study named "My study"
    Then the value of the "existing_study_type" attribute of the XML element "//STUDY_TYPE" should be "Other"
    Then the value of the "new_study_type" attribute of the XML element "//STUDY_TYPE" should be "<study_type>"

    Examples:
    | study_type |
    | Exome Sequencing |
    | Pooled Clone Sequencing |
    | TraDIS |

