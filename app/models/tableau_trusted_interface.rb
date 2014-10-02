module TableauTrustedInterface
  require 'rest_client'

  class TicketRejection < Error
  end

  # the client_ip parameter isn't necessary to send in the POST unless you have
  # wgserver.extended_trusted_ip_checking enabled (it's disabled by default)
  def tableau_get_trusted_ticket(tabserver, tabuser, target_site)
    RestClient.post "https://#{tabserver}/trusted", { :username => tabuser, :target_site => target_site }
  end

  def ticket_rejected
  	raise TicketRejection, 'The tableau server has rejected the request of a new ticket. Please, contact the administrators'
  end
end