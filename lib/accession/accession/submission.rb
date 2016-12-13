module Accession
  class Submission
    
    include ActiveModel::Model
    include Accession::Accessionable

    attr_reader :user, :sample, :service, :contact

    validates_presence_of :user, :sample

    def initialize(user, sample)
      @user = user
      @sample = sample

      if valid?
        @service = sample.service
        @contact = Contact.new(user)
      end
    end

    def to_xml
      _to_xml << sample.to_xml
    end

  private

    def _to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.SUBMISSION(
        XML_NAMESPACE,
        center_name: CENTER_NAME,
        broker_name: service.broker,
        alias: sample.submission_alias,
        submission_date: date
        ) {
          xml.CONTACTS { 
            xml.CONTACT(contact.to_h)
        }

        xml.ACTIONS { 
          xml.ACTION {
            xml.ADD(source: sample.filename,  schema: sample.schema_type)
            xml.tag!(service.visibility)
          }
        }
      }
      xml.target!
    end
  end
end