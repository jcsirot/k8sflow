require 'uri'

module K8sflow
  module Pg
    class PgTopic < Clitopic::Topic::Base
      register name: 'pg',
      description: 'Manage postgres actions'

      option :databases, "--databases KEY=postgresql_URI,KEY2=postgresql_URI2", Array, "List of preconfigured databases"

      option :uri, "--uri postresql", "Postgresql URI to connect"
      option :database, '-d', '--database database-name', 'Database name (from databases list)'
    end

    class PgBase < Clitopic::Command::Base
      class << self
        def kv_parse(list)
          vars = {}
          list.each do |e|
            sp = e.split("=")
            key = sp[0..-2].join("=")
            value = sp[-1]
            vars[key] = value
          end
          return vars
        end

        def hash_opt(opt)
          return {} if opt.nil?
          if opt.is_a?(Hash)
            hash = opt
          else
            hash = kv_parse(options[opt])
          end
          return hash
        end

        def parse_pg_uri(uri)
          p = URI.parse(uri)
          h = {
            database: p.path[1..-1],
            user: p.user,
            password: p.password,
            host: p.hostname,
            uri: uri
          }
          return h
        end

        def databases
          if @dbs.nil?
            @dbs = {}
            hash_opt(options[:databases]).each do |k,v|
              h = parse_pg_uri(v)
              @dbs[k] = h
            end
          end
          return @dbs
        end

        def database
          if options[:uri] != nil
            return parse_pg_uri(options[:uri])
          else
            return databases[options[:database]]
          end
        end
      end
    end

    class Psql < PgBase
      register name: 'psql',
      description: 'psql to the database',
      topic: 'pg'
      def self.call
        puts "PGPASSWORD=**** psql -h #{database[:host]} -U #{database[:user]} -d #{database[:database]}"
        exec("PGPASSWORD=#{database[:password]} psql -h #{database[:host]} -U #{database[:user]} -d #{database[:database]} #{@arguments}")
      end
    end

    class Capture < PgBase
      register name: 'capture',
      description: 'Create a database backup and send it to a [remote] directory',
      topic: 'pgbackup'

      option :dest, "--dest=DIR", "dest directory", default: "/tmp"
      def self.call
        file = File.new("#{options[:dest]}/#{database[:database]}_#{database[:host]}_#{Time.now.iso8601}.dump", 'wb')

        puts "PGPASSWORD=**** pg_dump --host #{database[:host]} --username #{database[:user]} --clean --format=c --no-owner --no-acl #{database[:database]} > #{file.path}"
        exec("PGPASSWORD=#{database[:password]} pg_dump --host #{database[:host]} --username #{database[:user]} --clean --format=c --no-owner --no-acl #{database[:database]} > #{file.path}")
        file.close
      end
    end

  end
end
