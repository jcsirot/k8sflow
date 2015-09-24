require 'optparse'
require 'optparse/time'
require 'pp'
require 'heroku-api'
require 'netrc'
require 'json'
require 'docker'

module K8sflow
  module Utils
    class Heroku
      HEROKU_API_HOST = "api.heroku.com"
      attr_accessor  :heroku, :api_token
      class << self
        def client
          if @client.nil?
            user, token = netrc[HEROKU_API_HOST]
            @client = Heroku::API.new(:api_key => token)
          end
          return @client
        end

        def netrc # :nodoc:
          @netrc ||= begin
                       File.exists?(netrc_path) ? Netrc.read(netrc_path) : raise(StandardError)
                     rescue => error
                       puts netrc_path
                       raise ".netrc missing or no entry found. Try `heroku auth:login`"
                     end
        end

        def netrc_path # :nodoc:
          default = Netrc.default_path
          encrypted = default + ".gpg"
          if File.exists?(encrypted)
            encrypted
          else
            default
          end
        end

        def envs(app, db_only=true)
          envs = client.get_config_vars(app).body
          #      pp "overrided vars: #{@options.envvars}"
          db_vars = ["DATABASE_URL",
                     "MEMCACHIER_PASSWORD",
                     "MEMCACHIER_SERVERS",
                     "MEMCACHIER_USERNAME",
                     "REDISTOGO_URL",
                     "REDIS_PROVIDER"]
          if db_only == true
            envs.select!{|k,v| db_vars.index(k) != nil}
          end
          pp envs
          return envs
        end
      end
    end
  end
end

module K8sflow
  module Run
    class Index < Clitopic::Command::Base
      register name: 'index',
      banner: 'Usage: k8sflow run [options] CMD',
      description: 'Run CMD on a (de)attached container',
      topic: {name: 'run', description: 'Run CMD on a (de)attached container'}

      option :port, "-p", "--port  ctn_port:host_port", Array, "Publish a container's port(s) to the host"
      option :port_all, "-P", "--port-all", Array, "Publish all exposed ports to random ports"
      option :detach, "-d", "--detach", "daemonize container"
      option :tag, "-t", "--tag TAG", "image-tag"
      option :repo, "-r", "--repo REPO", "image-repository"
      option :app, "-A", "--app APPNAME", "application name"
      option :envs, "-e", "--env VAR=VALUE,VAR2=VALUE2", Array, "envvars list"
      option :heroku, "--heroku APP", "get all envs from heroku"
      option :heroku_db, "--heroku-db", "get DB envs only from heroku"
      option :tty, "--[no-]tty", "Use tty"
      option :docker_api, "-h", "--host", "docker api endpoint"


      class << self
        attr_accessor :shortcuts, :defaults

        def defaults
          @default ||= {}
        end

        def shortcuts
          @shortcuts ||= {}
        end

        def get_cmd(args)
          if args.size == 0
            raise ArgumentError.new('no CMD')
          else
            cmd = args.join(" ").strip
            cmd = shortcuts[cmd] if shortcuts.has_key?(cmd)
            return cmd
          end
        end

        def env_vars(options)
          envs = {}
          if options.has_key?(:envs)
            options[:envs].each do |e|
              sp = e.split("=")
              key = sp[0..-2].join("=")
              value = sp[-1]
              envs[key] = value
            end
          end
          if options.has_key?(:heroku)
            envs.merge!( K8sflow::Utils::Heroku.envs(options[:heroku], options[:heroku_db]))
          end
          pp envs
          return envs
        end

        def docker_run(cmd, envs, options)
          Docker.url = options[:docker_api]
          container_info =  {
            'Cmd' => cmd.split(" "),
            'Image' => options[:tag],
            'Env' => envs.map{|k| "#{k[0]}=#{k[1]}"},
            'OpenStdin' => true
          }
          if !options[:detach]
            container_info["Tty"] = true
          end
          if options[:port]
            ctn_port, host_port = options[:port].split(":")
            container_info["HostConfig"] = {
              "PortBindings": { "#{ctn_port}/tcp": [{ "HostPort": host_port.to_s}] }
            }
          end
          if options[:port_all] == true
            container_info["PublishAllPorts"] = true
          end
          pp container_info
          container = Docker::Container.create(container_info)
          puts "container created with id: #{container.id}"
          if !options[:detach]
            puts "docker -H #{Docker.url} attach #{container.id}"
            exec("docker -H #{Docker.url} attach #{container.id}")
          end
        end

        def call(options, args)
          options = default.merge(options)
          cmd = get_cmd(args)
          envs = env_vars(options)
          docker_run(cmd, envs, options)
        end
      end


    end
  end
end
