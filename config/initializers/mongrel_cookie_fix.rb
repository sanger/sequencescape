if Rails.version =~ /2\.3\.\d+/ and Gem.available?('mongrel', '~> 1.1.5') and self.class.const_defined?(:Mongrel)
  Rails.logger.warn("***** WARNING: Rails 2.3.x & Mongrel 1.1.5 fix loaded from #{__FILE__} *****")

  module ActionController #:nodoc:
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