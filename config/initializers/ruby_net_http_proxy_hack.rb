# frozen_string_literal: true
# Connect based on standard library implimentation (via ruruby)
#
# Copyright (c) 1999-2007 Yukihiro Matsumoto
# Copyright (c) 1999-2007 Minero Aoki
# Copyright (c) 2001 GOTOU Yuuzou
#
# Originally adapted by Matt Denner.

# The sanger Squid proxy requires a user agent to be specified.
# Unfortunately the standard library does not pass our headers on
# to the proxy, and additionally provides no easy means of specifying
# custom headers.

# Ideally this hack would be less intrusive, but net/http isn't best designed
# for extensibility, and we can't subclass it as we usually use it as a dependency.
require 'net/http'

module Net
  class HTTP # rubocop:todo Style/Documentation
    def self.set_proxy_header(name, value)
      additional_proxy_headers[name] = value
    end

    def self.additional_proxy_headers
      @headers ||= {}
    end

    def additional_proxy_headers
      Net::HTTP.additional_proxy_headers
    end

    # Adapted from https://raw.githubusercontent.com/jruby/jruby/9.0.5.0/lib/ruby/stdlib/net/http.rb
    # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
    def connect # rubocop:todo Metrics/CyclomaticComplexity
      if proxy?
        conn_address = proxy_address
        conn_port = proxy_port
      else
        conn_address = address
        conn_port = port
      end

      D "opening connection to #{conn_address}:#{conn_port}..."
      s =
        Timeout.timeout(@open_timeout, Net::OpenTimeout) do
          TCPSocket.open(conn_address, conn_port, @local_host, @local_port)
        end
      s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      D 'opened'
      if use_ssl?
        ssl_parameters = Hash.new
        iv_list = instance_variables
        SSL_IVNAMES.each_with_index do |ivname, i|
          if iv_list.include?(ivname) && (value = instance_variable_get(ivname))
            ssl_parameters[SSL_ATTRIBUTES[i]] = value if value
          end
        end
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.set_params(ssl_parameters)
        D "starting SSL for #{conn_address}:#{conn_port}..."
        s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
        s.sync_close = true
        D 'SSL established'
      end
      @socket = BufferedIO.new(s)
      @socket.read_timeout = @read_timeout
      @socket.continue_timeout = @continue_timeout
      @socket.debug_output = @debug_output
      if use_ssl?
        begin
          if proxy?
            buf = "CONNECT #{@address}:#{@port} HTTP/#{HTTPVersion}\r\n"
            buf << "Host: #{@address}:#{@port}\r\n"

            # MODIFICATION BEGINS
            additional_proxy_headers.each { |k, v| buf << "#{k}: #{v}\r\n" }

            # MODIFICATION ENDS
            if proxy_user
              credential = ["#{proxy_user}:#{proxy_pass}"].pack('m')
              credential.delete!("\r\n")
              buf << "Proxy-Authorization: Basic #{credential}\r\n"
            end
            buf << "\r\n"
            @socket.write(buf)
            HTTPResponse.read_new(@socket).value
          end
          if @ssl_session &&
               (Process.clock_gettime(Process::CLOCK_REALTIME) < @ssl_session.time.to_f + @ssl_session.timeout)
            s.session = @ssl_session if @ssl_session
          end

          # Server Name Indication (SNI) RFC 3546
          s.hostname = @address if s.respond_to? :hostname=
          Timeout.timeout(@open_timeout, Net::OpenTimeout) { s.connect }
          s.post_connection_check(@address) if @ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE
          @ssl_session = s.session
        rescue => e
          D "Conn close because of connect error #{e}"
          @socket.close if @socket && (not @socket.closed?)
          raise e
        end
      end
      on_connect
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    private :connect
  end
end

Net::HTTP.set_proxy_header('User-Agent', 'Sequencescape')
