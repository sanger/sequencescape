@xml @study @api
Feature: The XML for the sequencescape API
  Background:
    Given all of this is happening at exactly "2010-Oct-03 18:21:11+01:00"
    Given there is at least one administrator

    Given the following user records
      | login   | first_name | last_name   |
      | owner   | I am       | The Owner   |
      | manager | I am       | The Manager |

    Given I have an active study called "Study for XML"
    And the faculty sponsor for study "Study for XML" is "Jack Sponsor"

    And the study "Study for XML" has samples contaminated with human DNA
    And the study "Study for XML" does not contain samples commercially available
    And the study "Study for XML" has samples which need x and autosome data removed
    And the study "Study for XML" has the following contacts
      | login   | role    |
      | owner   | owner   |
      | manager | manager |

  Scenario: Requesting XML for a study
    When I request XML for the study named "Study for XML"
    Then ignoring "id|user_id" the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <study api_version="0.6">
        <id>740</id>
        <name>Study for XML</name>
        <active>true</active>
        <user_id>2230</user_id>
        <managers>
          <manager>
            <login>manager</login>
            <email>manager@example.com</email>
            <name>I am The Manager</name>
            <id>2229</id>
          </manager>
        </managers>
        <owners>
          <owner>
            <login>owner</login>
            <email>owner@example.com</email>
            <name>I am The Owner</name>
            <id>2228</id>
          </owner>
        </owners>
        <!-- Family has been deprecated -->
        <family_id></family_id>
        <created_at>2010-10-03 18:21:11 +0100</created_at>
        <updated_at>2010-10-03 18:21:11 +0100</updated_at>
        <descriptors>
          <descriptor>
            <name>Number of gigabases per sample (minimum 0.15)</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Reason for delaying release</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?</name>
            <value>Yes</value>
          </descriptor>
          <descriptor>
            <name>Does this study require the removal of X chromosome and autosome sequence?</name>
            <value>Yes</value>
          </descriptor>
          <descriptor>
            <name>What sort of study is this?</name>
            <value>genomic sequencing</value>
          </descriptor>
          <descriptor>
            <name>What is the reason for preventing data release?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Will you be using WTSI's standard access agreement?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Reference Genome</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Study Visibility</name>
            <value>Hold</value>
          </descriptor>
          <descriptor>
            <name>ENA Study Accession Number</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Study name abbreviation</name>
            <value>WTCCC</value>
          </descriptor>
          <descriptor>
            <name>Study Type</name>
            <value>Not specified</value>
          </descriptor>
          <descriptor>
            <name>Has this been approved?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Delay for</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Title</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Comment regarding prevention of data release and approval</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>How is the data release to be timed?</name>
            <value>standard</value>
          </descriptor>
          <descriptor>
            <name>Abstract</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Study description</name>
            <value>Some study on something</value>
          </descriptor>
          <descriptor>
            <name>Alignments in BAM</name>
            <value>true</value>
          </descriptor>
          <descriptor>
          <name>Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?</name>
          <value>No</value>
          </descriptor>
          <descriptor>
            <name>Has the delay period been approved by the data sharing committee for this project?</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>ENA Project ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>Comment regarding data release timing and approval</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>What is the data release strategy for this study?</name>
            <value>open</value>
          </descriptor>
          <descriptor>
            <name>Do any of the samples in this study contain human DNA?</name>
            <value>No</value>
          </descriptor>
          <descriptor>
            <name>Faculty Sponsor</name>
            <value>Jack Sponsor</value>
          </descriptor>
          <descriptor>
            <name>Please explain the reason for delaying release (e.g., pre-existing collaborative agreement)</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>SNP parent study ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>SNP study ID</name>
            <value></value>
          </descriptor>
          <descriptor>
            <name>HMDMC approval number</name>
            <value></value>
          </descriptor>
          <descriptor><name>EGA DAC Accession Number</name></descriptor>
          <descriptor><name>EGA Policy Accession Number</name></descriptor>
          <descriptor><name>Policy</name></descriptor>
          <descriptor><name>ArrayExpress Accession Number</name></descriptor>
        </descriptors>
      </study>
      """

