require 'pp'
require 'heroku-api'
require 'netrc'
require 'json'

module K8sflow
  module Utils
    class HerokuClient
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
