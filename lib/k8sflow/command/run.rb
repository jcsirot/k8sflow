require 'optparse'
require 'optparse/time'
require 'docker'
require 'k8sflow/utils/heroku'
module K8sflow
  module Command

    class Run < Clitopic::Command::Base
      register name: 'index',
               banner: 'Usage: k8sflow run [options] CMD',
               description: "Run CMD on a (de)attached container

Exemples:
Run a rails console
$ k8sflow run -t 2.27.3 -r mydocker/repo -e APP_ENV=production -h tcp://docker-host:4243 rails console

Run a web server detached and bind container port to host port
$ k8sflow run -t 2.10 -p 3000:3000 'run server -p 3000'
",
               topic: {name: 'run', description: 'Run CMD on a (de)attached container'}

      option :port, "-p", "--port  ctn_port:host_port", Array, "Publish a container's port(s) to the host"
      option :port_all, "-P", "--port-all", Array, "Publish all exposed ports to random ports"
      option :detach, "-d", "--detach", "daemonize container", default: false
      option :tag, "-t", "--tag TAG", "image-tag"
      option :registry, "-r", "--registry REPO", "image-repository"
      option :app, "-A", "--app APPNAME", "application name"
      option :envs, "-e", "--env VAR=VALUE,VAR2=VALUE2", Array, "envvars list"
      option :heroku, "--heroku APP", "get all envs from heroku"
      option :heroku_db, "--heroku-db", "get DB envs only from heroku"
      option :tty, "--[no-]tty", "Use tty"
      option :docker_api, "-h", "--host HOST", "docker api endpoint", default: "unix://"
      option :aliases, "--aliases a=x,b=y", "commands aliases, usefull in the default file"

      class << self
        attr_accessor :aliases

        def aliases
          @aliases ||= {}
        end

        def get_cmd(args)
          if args.size == 0
            raise ArgumentError.new('no CMD')
          else
            cmd = args.join(" ").strip
            puts cmd
            if !@options[:aliases].nil? && @options[:aliases].is_a?(Hash)
              @aliases.merge!(@options[:aliases])
            end
            cmd = aliases[cmd] if aliases.has_key?(cmd)
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
            envs.merge!( K8sflow::Utils::HerokuClient.envs(options[:heroku], options[:heroku_db]))
          end
          pp envs
          return envs
        end

        def docker_run(cmd, envs, options)
          Docker.url = options[:docker_api]
          container_info =  {
            'Cmd' => cmd.split(" "),
            'Image' => "#{options[:registry]}:#{options[:tag]}",
            'Env' => envs.map{|k| "#{k[0]}=#{k[1]}"},
            'OpenStdin' => true
          }
          if !options[:detach]
            container_info["Tty"] = true
          end
          if options[:port]
            ctn_port, host_port = options[:port].split(":")
            container_info["HostConfig"] = {
              "PortBindings" => { "#{ctn_port}/tcp" => [{ "HostPort" => host_port.to_s}] }
            }
          end
          if options[:port_all] == true
            container_info["PublishAllPorts"] = true
          end
          pp container_info
          container = Docker::Container.create(container_info)
          container.start
          puts "container created with id: #{container.id}"
          if !options[:detach]
            puts "docker -H #{Docker.url} attach #{container.id}"
            exec("docker -H #{Docker.url} attach #{container.id}")
          end
        end

        def call
          pp options
          cmd = get_cmd(arguments)
          envs = env_vars(options)
          docker_run(cmd, envs, options)
        end
      end


    end
  end
end
