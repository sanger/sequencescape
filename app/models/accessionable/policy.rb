# frozen_string_literal: true
# Represents policy information about who will have access to information associatied
# with manages (EGA) {Accessionable::Study studies}
# Comprised of a {Accessionable::Dac DAC} and a URL.
# Should ideally be a completely separate record  from {Study} but currently just
# a group of attributes in the {Study::Metadata}
class Accessionable::Policy < Accessionable::Base
  attr_reader :policy_url, :dac_accession_number, :title

  def initialize(study)
    @study = study

    @name = "Policy for study - #{study.name} - ##{study.id}"
    @policy_url = study.study_metadata.dac_policy
    @title = study.study_metadata.dac_policy_title

    # @dac_refname = study.dac_refname
    @dac_accession_number = study.dac_accession_number
    super(study.policy_accession_number)
  end

  def errors
    [].tap do |errors|
      unless @dac_accession_number
        errors << 'DAC Accession number not found. Please get an accession number for the DAC.'
      end
    end
  end

  def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.POLICY_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
      xml.POLICY(alias: self.alias, accession: accession_number, center_name: center_name) do
        xml.TITLE title
        xml.DAC_REF(accession: dac_accession_number)
        xml.POLICY_FILE policy_url
      end
    end
    xml.target!
  end

  def update_accession_number!(user, accession_number)
    @accession_number = accession_number
    @study.study_metadata.ega_policy_accession_number = accession_number
    @study.save!
    @study.events.created_accession_number!('policy', user)
  end

  def protect?(service)
    service.policy_visibility(@study) == AccessionService::PROTECT
  end

  def accessionable_id
    @study.id
  end
end
