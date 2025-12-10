# frozen_string_literal: true
# Represents a Data Access Committee who co-ordinate access to managed (EGA)
# {Accessionable::Study studies}. Should ideally be a completely separate record
# from {Study} but currently just a group of attributes in the {Study::Metadata}
class Accessionable::Dac < Accessionable::Base
  attr_reader :contacts

  def initialize(study)
    @study = study
    @name = study.dac_refname
    @contacts =
      study.data_access_contacts.map do |contact|
        { email: contact.email, name: contact.name, organisation: AccessionService::CENTER_NAME }
      end

    super(study.dac_accession_number)
  end

  def errors
    [].tap { |errors| errors << 'Data Access Contacts Empty. Please add a contact' if @contacts.empty? }
  end

  def xml # rubocop:todo Metrics/MethodLength
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.DAC_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
      xml.DAC(alias: self.alias, accession: accession_number, center_name: center_name) do
        xml.CONTACTS do
          contacts.each do |contact|
            xml.CONTACT(name: contact[:name], email: contact[:email], organisation: contact[:organisation])
          end
        end
      end
    end
    xml.target!
  end

  def update_accession_number!(user, accession_number)
    @accession_number = accession_number
    @study.study_metadata.ega_dac_accession_number = accession_number
    @study.save!
    @study.events.assigned_accession_number!('DAC', accession_number, user)
  end

  def protect?(service)
    service.dac_visibility(@study) == AccessionService::PROTECT
  end

  def accessionable_id
    @study.id
  end
end
