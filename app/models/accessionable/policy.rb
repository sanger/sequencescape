class Accessionable::Policy < Accessionable::Base

  attr_reader :policy_text, :dac_accession_number, :title

  def initialize(study)
    @study = study

    @name = "Policy for study - #{study.name} - ##{study.id}"
    @policy_text = study.study_metadata.dac_policy
    #@dac_refname = study.dac_refname
    @dac_accession_number = study.dac_accession_number
    super(study.policy_accession_number)

  end

  def errors
    [].tap do |errors|
      errors << "DAC Accession number not found. Please get an accession number for the DAC." unless @dac_accession_number
    end
  end

  def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.POLICY_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.POLICY(:alias => self.alias,
                 :accession => self.accession_number,
                 :center_name => self.center_name) {
      xml.TITLE self.title
      xml.DAC_REF(:accession => self.dac_accession_number)
      xml.POLICY_TEXT self.policy_text
    }
    }
    return xml.target!
  end

  def update_accession_number!(user, accession_number)
    @accession_number = accession_number
    add_updated_event(user, "Policy for Study #{@study.id}", @study) if @accession_number
    @study.study_metadata.ega_policy_accession_number = accession_number
    @study.save!
  end

  def protect?(service)
    service.policy_visibility(@study) == AccessionService::Protect
  end

  def object_id
    @study.id
  end
end
