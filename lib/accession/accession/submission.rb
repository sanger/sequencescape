module Accession
  # Made up of a sample, user and service
  # Used by Request to extract relevant information to send to appropriate accessioning service
  class Submission
    include ActiveModel::Model
    include Accession::Accessionable

    attr_reader :user, :sample, :service, :contact, :response

    delegate :accessioned?, to: :response

    delegate :ebi_alias, :ebi_alias_datestamped, to: :sample

    validates_presence_of :user, :sample
    validate :check_sample, if: proc { |s| s.sample.present? }

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
        alias: sample.ebi_alias_datestamped,
        submission_date: date
        ) {
          xml.CONTACTS {
            xml.CONTACT(contact.to_h)
          }

        xml.ACTIONS {
          xml.ACTION {
            xml.ADD(source: sample.filename, schema: sample.schema_type)
          }
          xml.ACTION {
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

    # Accessioning requires a submission and sample file
    # Payload consists of a hash of relevant files
    # These files can be opened when the request is sent
    class Payload
      include Enumerable

      attr_reader :files

      def initialize(accessionables)
        @files = {}.tap do |f|
          accessionables.each do |accessionable|
            f[accessionable.schema_type.upcase] = accessionable.to_file
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

  private

    def check_sample
      unless sample.valid?
        sample.errors.each do |key, value|
          errors.add key, value
        end
      end
    end
  end
end
