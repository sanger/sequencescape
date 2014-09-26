module TableauTrustedInterface
  require 'net/http'
  require 'uri'
 
  # the client_ip parameter isn't necessary to send in the POST unless you have
  # wgserver.extended_trusted_ip_checking enabled (it's disabled by default)
  def tableau_get_trusted_ticket(tabserver, tabuser, client_ip)
    post_data = {
      "username" => tabuser,
      "client_ip" => client_ip
    }
    begin
      response = Net::HTTP.post_form(URI.parse("http://#{tabserver}/trusted"), post_data)
 
      case response
      when Net::HTTPSuccess
        return response.body.to_s
      else
        return "-1"
      end
    rescue Errno::ECONNREFUSED
      return "-1"
    end
  end
end