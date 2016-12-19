module Accession
  class Submission
    include ActiveModel::Model
    include Accession::Accessionable

    attr_reader :user, :sample, :service, :contact, :response

    delegate :accessioned?, to: :response

    validates_presence_of :user, :sample

    def initialize(user, sample)
      @user = user
      @sample = sample
      @response = Accession::NullResponse.new

      if valid?
        @service = sample.service
        @contact = Contact.new(user)
      end
    end

    def to_xml
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
            xml.ADD(source: sample.filename, schema: sample.schema_type)
            xml.tag!(service.visibility)
          }
        }
      }
      xml.target!
    end

    def post
      @response = Accession::Request.post(self) if valid?
    end

    def update_accession_number
      if accessioned?
        sample.update_accession_number(response.accession_number)
      end
    end

    def payload
      @payload ||= Payload.new([self, sample])
    end

    class Payload
      include Enumerable

      attr_reader :files

      def initialize(accessionables)
        @files = {}.tap do |f|
          accessionables.each do |accessionable|
            f[accessionable.schema_type] = accessionable.to_file
          end
        end
      end

      def each(&block)
        files.each(&block)
      end

      def open
        Hash[files.collect { |k, v| [k, v.open] }]
      end

      def close!
        files.values.each do |file|
          file.close!
        end
      end
    end
  end
end
