# This is a monkeypatch for fixing an issue with Rails 2.3.8 and Mongrel.  Full details of why
# this is here can be found at:
#
# https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/4690-mongrel-doesnt-work-with-rails-238#ticket-4690-18
#
# The short details are that Rack HeadersHash behaves differently if you request a header than
# when you iterate over all headers.  'cookie' here is actually an Array but if you join it
# something is rendered invalid in Mongrel and *no* headers are sent.  We fix this by specifically
# dealing with that header here.
#
# The code here is pulled from the gist https://gist.github.com/471663 which has been built on top
# of my original suggestion for a fix.
if Rails.version =~ /2\.3\.\d+/ && Gem.available?('mongrel', Gem::Requirement.new('~>1.1.5')) && self.class.const_defined?(:Mongrel)
  # Pulled right from latest rack. Old looked like this in 1.1.0 version.
  #
  # def [](k)
  #   super(@names[k] ||= @names[k.downcase])
  # end
  #
  module Rack
    module Utils
      class HeaderHash < Hash
        def [](k)
          super(@names[k]) if @names[k]
          super(@names[k.downcase])
        end
      end
    end
  end

  # Code pulled from the ticket above.
  #
  class Mongrel::CGIWrapper
    def header_with_rails_fix(options = 'text/html')
      @head['cookie'] = options.delete('cookie').flatten.map { |v| v.sub(/^\n/,'') } if options.class != String and options['cookie']
      header_without_rails_fix(options)
    end
    alias_method_chain :header, :rails_fix
  end

  # Pulled right from 2.3.8 ActionPack. Simple diff was
  #
  # if headers.include?('Set-Cookie')
  #   headers['cookie'] = headers.delete('Set-Cookie').split("\n")
  # end
  #
  # to
  #
  # if headers['Set-Cookie']
  #   headers['cookie'] = headers.delete('Set-Cookie').split("\n")
  # end
  #
  module ActionController
    class CGIHandler
      def self.dispatch_cgi(app, cgi, out = $stdout)
        env = cgi.__send__(:env_table)
        env.delete "HTTP_CONTENT_LENGTH"
        cgi.stdinput.extend ProperStream
        env["SCRIPT_NAME"] = "" if env["SCRIPT_NAME"] == "/"
        env.update({
          "rack.version" => [0,1],
          "rack.input" => cgi.stdinput,
          "rack.errors" => $stderr,
          "rack.multithread" => false,
          "rack.multiprocess" => true,
          "rack.run_once" => false,
          "rack.url_scheme" => ["yes", "on", "1"].include?(env["HTTPS"]) ? "https" : "http"
        })
        env["QUERY_STRING"] ||= ""
        env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
        env["REQUEST_PATH"] ||= "/"
        env.delete "PATH_INFO" if env["PATH_INFO"] == ""
        status, headers, body = app.call(env)
        begin
          out.binmode if out.respond_to?(:binmode)
          out.sync = false if out.respond_to?(:sync=)
          headers['Status'] = status.to_s
          if headers['Set-Cookie']
            headers['cookie'] = headers.delete('Set-Cookie').split("\n")
          end
          out.write(cgi.header(headers))
          body.each { |part|
            out.write part
            out.flush if out.respond_to?(:flush)
          }
        ensure
          body.close if body.respond_to?(:close)
        end
      end
    end
  end

end

