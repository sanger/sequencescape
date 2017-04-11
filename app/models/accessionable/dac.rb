# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Accessionable::Dac < Accessionable::Base
  attr_reader :contacts
  def initialize(study)
    @study = study
    @name = study.dac_refname
    @contacts = study.send('Data Access Contacts').map do |contact|
      {
        email: contact.email,
        name: contact.name,
        organisation: AccessionService::CenterName
      }
    end

    super(study.dac_accession_number)
  end

  def errors
    [].tap do |errors|
      if @contacts.empty?
        errors << 'Data Access Contacts Empty. Please add a contact'
      end
    end
  end

  def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.DAC_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.DAC(alias: self.alias, accession: accession_number, center_name: center_name) {
      xml.CONTACTS {
      contacts.each do |contact|
      xml.CONTACT({
        name: contact[:name],
        email: contact[:email],
        organisation: contact[:organisation]
        }.tap do |att|
         att[:telephone] = tel if (tel = contact[:telephone])
        end)
      end
      }
      }
    }
    xml.target!
  end

  def update_accession_number!(user, accession_number)
    @accession_number = accession_number
    add_updated_event(user, "DAC for Study #{@study.id}", @study) if @accession_number
    @study.study_metadata.ega_dac_accession_number = accession_number
    @study.save!
  end

  def protect?(service)
    service.dac_visibility(@study) == AccessionService::Protect
  end

  def accessionable_id
    @study.id
  end
end
