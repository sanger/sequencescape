require File.expand_path(File.join(File.dirname(__FILE__), 'fake_sinatra_service.rb'))

class FakeAccessionService < FakeSinatraService
  def initialize(*args, &block)
    super
    configatron.accession_url      = "http://#{host}:#{port}/accession_service/"
    configatron.accession_view_url = "http://#{host}:#{port}/view_accession/"
  end

  def bodies
    @bodies ||= []
  end

  def clear
    @bodies = []
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
    self.bodies << %Q{<RECEIPT success="false"><ERROR>#{ message }</ERROR></RECEIPT>}
  end

  def next!
    self.bodies.pop
  end

  def service
    Service
  end

  class Service < FakeSinatraService::Base
    post('/accession_service/era_accession_login') do
      response = FakeAccessionService.instance.next! or halt(500)
      headers('Content-Type' => 'text/xml')
      body(response)
    end

    post('/accession_service/ega_accession_login') do
      response = FakeAccessionService.instance.next! or halt(500)
      headers('Content-Type' => 'text/xml')
      body(response)
    end
  end
end

FakeAccessionService.install_hooks(self, '@accession-service')
