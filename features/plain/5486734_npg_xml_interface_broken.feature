@api @xml @npg @asset
Feature: NPG XML interface
  Background:
    Given I have a project called "Project testing the NPG XML interface"
    And I have an active study called "Study testing the NPG XML interface"

  # The important thing to check is that the 'key' elements exist
  Scenario: Requesting the XML for a library tube that has been involved in paired end sequencing
    Given the library tube named "Tube" exists
    And the library tube "Tube" has been involved in a "Paired end sequencing" request within the study "Study testing the NPG XML interface" for the project "Project testing the NPG XML interface"

    When I retrieve the XML for the asset called "Tube"
    Then ignoring "id|sample" the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <asset api_version="0.6">
        <id>1</id>
        <type>LibraryTube</type>
        <name>Tube</name>
        <public_name></public_name>
        <sample_id></sample_id>
        <qc_state></qc_state>

        <children>
        </children>
        <parents>
        </parents>
        <requests>
          <request>
            <id>1</id>
            <properties>
              <property>
                <key>customer_accepts_responsibility</key>
                <name>Still charge on fail</name>
                <value>false</value>
              </property>
              <property>
                <key>read_length</key>
                <name>Read length</name>
                <value>76</value>
              </property>
              <property>
                <key>fragment_size_required_from</key>
                <name>Fragment size required (from)</name>
                <value>1</value>
              </property>
              <property>
                <key>fragment_size_required_to</key>
                <name>Fragment size required (to)</name>
                <value>21</value>
              </property>
            </properties>
          </request>
        </requests>
      </asset>
      """

  Scenario: Requesting the XML for a sample tube that has been involved in library creation
    Given the sample tube named "Tube" exists
    And the sample tube "Tube" has been involved in a "Library creation" request within the study "Study testing the NPG XML interface" for the project "Project testing the NPG XML interface"

    When I retrieve the XML for the asset called "Tube"
    Then ignoring "id|sample_id|sample" the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <asset api_version="0.6">
        <id>1</id>
        <type>SampleTube</type>
        <name>Tube</name>
        <public_name></public_name>
        <sample_id>1</sample_id>
        <qc_state></qc_state>

        <children>
        </children>
        <parents>
        </parents>
        <requests>
          <request>
            <id>1</id>
            <properties>
              <property>
                <key>customer_accepts_responsibility</key>
                <name>Still charge on fail</name>
                <value>false</value>
              </property>
              <property>
                <key>read_length</key>
                <name>Read length</name>
                <value>76</value>
              </property>
              <property>
                <key>gigabases_expected</key>
                <name>Gigabases expected</name>
              </property>
              <property>
                <key>library_type</key>
                <name>Library type</name>
                <value>Standard</value>
              </property>
              <property>
                <key>fragment_size_required_from</key>
                <name>Fragment size required (from)</name>
                <value>1</value>
              </property>
              <property>
                <key>fragment_size_required_to</key>
                <name>Fragment size required (to)</name>
                <value>20</value>
              </property>
            </properties>
          </request>
        </requests>
      </asset>
      """
