# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class FakeAccessionService
  include Singleton

  # Unfortunately Webmock doesn't handle multipart files, so we can't access
  # the payload. Instead we set up our own evesdropping Rest Client class
  # and use that instead. (This used to do class evan on the original class)
  # but that would end up evesdropping on everything.
  class EvesdropResource < RestClient::Resource
    def post(payload)
      FakeAccessionService.instance.add_payload(payload)
      super(payload)
    end
  end

  def self.install_hooks(target, tags)
    target.instance_eval do
      Before(tags) do |scenario|

        # Set up our evesdropper
        AccessionService.rest_client_class = EvesdropResource

        # We actually know what the value of these will be
        # but we include the lookup here, as we're more keen
        # on where they are source from, rather than what they are
        accession_url = configatron.accession_url

        # Currently logins are encoded in the URL directly
        # An HTTP auth system is now available though, so we
        # should switch once we get the chance.
        era_login = configatron.era_accession_login
        ega_login = configatron.ega_accession_login

        [era_login, ega_login].each do |service_login|
          stub_request(:post, "#{accession_url}#{service_login}").to_return do |request|
            response = FakeAccessionService.instance.next!
            status = response.nil? ? 500 : 200
            {
              headers: { 'Content-Type' => 'text/xml' },
              body: response,
              status: status
            }
          end
        end
      end

      After(tags) do |scenario|
        FakeAccessionService.instance.clear
        # Remove the evesdropper
        AccessionService.rest_client_class = RestClient::Resource
      end
    end
  end

  def bodies
    @bodies ||= []
  end

  def sent
    @sent ||= []
  end

  def last_received
    @last_received
  end

  def clear
    @bodies = []
    @sent = []
  end

  def success(type, accession, body = "")
    model = type.upcase
    self.bodies << <<-XML
      <RECEIPT success="true">
        <#{model} accession="#{accession}">#{body}</#{model}>
        <SUBMISSION accession="EGA00001000240" />
      </RECEIPT>
    XML
  end

  def failure(message)
    self.bodies << %Q{<RECEIPT success="false"><ERROR>#{message}</ERROR></RECEIPT>}
  end

  def next!
    @last_received = self.bodies.pop
  end

  def service
    Service
  end

  def add_payload(payload)
    sent.push(Hash[*payload.map { |k, v| [k, v.readlines] }.map { |k, v| [k, (v unless v.empty?)] }.flatten])
  end

end

require 'rest_client'

FakeAccessionService.install_hooks(self, '@accession-service')
