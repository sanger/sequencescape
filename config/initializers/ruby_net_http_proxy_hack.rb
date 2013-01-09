require 'net/http'

module Net
  class HTTP
    module ProxyDelta
      def self.set_header(name, value)
        additional_headers[name] = value
      end

      def self.additional_headers
        @headers ||= {}
      end

      def additional_headers
        ProxyDelta.additional_headers
      end

      def connect
        D "opening connection to #{conn_address()}..."
        s = timeout(@open_timeout) { TCPSocket.open(conn_address(), conn_port()) }
        D "opened"
        if use_ssl?
          unless @ssl_context.verify_mode
            warn "warning: peer certificate won't be verified in this SSL session"
            @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
          s.sync_close = true
        end
        @socket = BufferedIO.new(s)
        @socket.read_timeout = @read_timeout
        @socket.debug_output = @debug_output
        if use_ssl?
          if proxy?
            @socket.writeline sprintf('CONNECT %s:%s HTTP/%s',
                                      @address, @port, HTTPVersion)
            @socket.writeline "Host: #{@address}:#{@port}"
            additional_headers.each { |k,v| @socket.writeline("#{k}: #{v}") }
            if proxy_user
              credential = ["#{proxy_user}:#{proxy_pass}"].pack('m')
              credential.delete!("\r\n")
              @socket.writeline "Proxy-Authorization: Basic #{credential}"
            end
            @socket.writeline ''
            HTTPResponse.read_new(@socket).value
          end
          s.connect
          if @ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE
            s.post_connection_check(@address)
          end
        end
        on_connect
      end
      private :connect
    end
  end
end

Net::HTTP::ProxyDelta.set_header('User-Agent', 'Sequencescape')
