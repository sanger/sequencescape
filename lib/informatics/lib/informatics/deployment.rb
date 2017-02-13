module Informatics
  class Deployment
    attr_accessor :cap, :app_name, :deploy_name, :repository_location, :log_location, :config_location, :nginx_location
    attr_accessor :service_uri, :service_port, :balanced_ports, :html_root, :nginx_binaries

    def self.configure(options)
      a = new
      c = options[:with]
      a.cap = c
      yield a

      # Set deployment variable in Capistrano::Configure to make it available
      # to the rest of the deployment scripts
      c.set :deployment, a
    end

    def start_nginx_from(l)
      @nginx_binaries = l
      cap.set :nginx_binaries, l
    end

    def root(h)
      @html_root = h
    end

    def balanced_against(a)
      puts "SETTING BALANCED PORTS: #{a}"
      @balanced_ports = a
    end

    def balanced_ports
      puts "GETTING BALANCED PORTS: #{@balanced_ports}"
      @balanced_ports
    end

    def accessible_at(u)
      @service_uri = u
    end

    def on(p)
      @service_port = p
    end

    def nginx_config
      parsed('vendor/plugins/informatics/assets/deployment/nginx.conf.erb')
    end

    def mime_types
      parsed('vendor/plugins/informatics/assets/deployment/mime.types.erb')
    end

    def mongrel_config
      parsed('vendor/plugins/informatics/assets/deployment/server.yml.erb')
    end

    def logrotate_config
      parsed('vendor/plugins/informatics/assets/deployment/logrotate.conf.erb')
    end

    def nginx_files(f)
      @nginx_location = f
    end

    def configuration(c)
      @config_location = c
    end

    def named(n)
      @app_name = n
      cap.set :application, n
    end

    def log_to(l)
      @log_location = l
    end

    def deploy_as(n)
      @deploy_name = n
      cap.set :deploy_name, n
    end

    def repository(r)
      @repository_location = r
      cap.set :repository, r
    end

    private

      def parsed(filename)
        ERB.new(File.new(filename, 'r').read).result(binding)
      end
  end
end
