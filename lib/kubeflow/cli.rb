require 'optparse'
require 'ostruct'

module Kubeflow
  class InitCmd
    def self.index(args)
      options = OpenStruct.new
      options.verbose = false
      opt_parser = OptionParser.new do |opts|
        options.banner = "Usage: kubeflow  [options]"
        opts.on("--dry", "Run command on the image") do |cmd|
          options.verbose = true
        end
      end
      opt_parser.parse!(args)
      return options
    end

    def self.file(args)
      options = OpenStruct.new
      options.verbose = false
      opt_parser = OptionParser.new do |opts|
        options.banner = "Usage: kubeflow init:file [options]"
        opts.on("--verbose", "Run command on the image") do |cmd|
          options.verbose = true
        end
      end
      opt_parser.parse!(args)
      return options
    end

  end

  class RunCmd
    def self.index(args)
      options = OpenStruct.new
      options.verbose = false

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: rails-k8s [options]"
        options.tag = "latest"
        options.cmd = "rails console"
        options.port = nil
        options.tty = true
        options.app = nil
        options.env =  nil
        options.rails_env = "production"
        options.envvars = {"FORCE_HTTPS" => false, "RAILS_ENV" => options.rails_env}
        options.heroku_app = nil
        options.attach = true
        options.only_heroku_dbs = false
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("--run CMD", "Run command on the image") do |cmd|
          if cmd == "console" || cmd == "c"
            cmd = "rails console"
          elsif cmd == "s" || cmd == "s"
            cmd = "rails s"
          end
          options.cmd = cmd

        end

        opts.on("-p", "--port PORT", "localhost port to access the server") do |port|
          options.port = port
        end
        opts.on("-d", "--detach", "daemonize container") do
          options.attach = false
        end

        # Mandatory argument.
        opts.on("-t", "--tag image-tag",
                "Require the image tag to run") do |tag|
          options.tag = "arkena/osm-backend:#{tag}"
        end
        opts.on("--tty",
                "Require the image tag to run") do |tag|
          options.tag = "arkena/osm-backend:#{tag}"
        end

        opts.on("-A", "--app APP:ENV", "application to connect to. i.e OSM:DEV") do |app|
          app,env = app.split(":")
          #        @options.envvars["APP_ENV"] = app
          options.app = app
          options.env = env
        end

        opts.on("--heroku app-name", "get all envs from heroku") do |appname|
          options.only_heroku_dbs = false
          options.heroku_app = appname
        end

        opts.on("--db-heroku app-name", "get only DB env vars from heroku") do |appname|
          options.only_heroku_dbs = true
          options.heroku_app = appname
        end

        opts.on("-e", "--env VAR=VALUE,VAR2=VALUE2...", Array, "envvars list") do |envs|
          envs.each do |e|
            sp = e.split("=")
            key = sp[0..-2].join("=")
            value = sp[-1]
            puts options.envvars
            options.envvars[key] = value
          end
        end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        # Another typical switch to print the version.
        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end
      end

      opt_parser.parse!(args)
      options
    end  # parse()
  end
  require 'kubeflow'
  load('kubeflow/helpers.rb')
  class Cli

    extend Kubeflow::Helpers

    def self.start(*args)
      $stdin.sync = true if $stdin.isatty
      $stdout.sync = true if $stdout.isatty
      command = args.shift.strip rescue "help"
      require 'kubeflow/command'
      Kubeflow::Command.load
      Kubeflow::Command.run(command, args)
    rescue Errno::EPIPE => e
      error(e.message)
    rescue Interrupt => e
      `stty icanon echo` unless running_on_windows?
      if ENV["KUBEFLOW_DEBUG"]
        styled_error(e)
      else
        error("Command cancelled.", false)
      end
    rescue => error
      styled_error(error)
      exit(1)
    end


    def self.run(args)
      commands = {"run" => Kubeflow::RunCmd,
        "init" => Kubeflow::InitCmd
      }
      command = args.shift.strip rescue "help"
      klass, method = command.split(":")
      if method.nil?
        method = :index
      end
      puts commands[klass].send method, args
    end
  end
end
