module K8sflow
  module Pg
    class PgTopic < Clitopic::Topic::Base
      register name: 'pg',
               description: 'Manage postgres actions'

      option :databases, "--databases KEY=postgresql_URI,KEY2=postgresql_URI2", Array, "List of preconfigured databases"

      option :database, '-d', '--database DATABASE', 'Database name or URI', required: true
      option :ssl, "--ssl", "enable sslmode"
    end
  end
end

class PgBase < Clitopic::Command::Base
  class << self
    include Clitopic::Helpers
    def exec_sql(sql)
      begin
        ENV["PGPASSWORD"] = database[:password]
        ENV["PGSSLMODE"]  = (database[:host] == 'localhost' ?  'prefer' : 'require' )
        user_part = database[:user] ? "-U #{database[:user]}" : ""
        output = `#{psql_cmd} -c "#{sql}" #{user_part} -h #{database[:host]} -p #{database[:port] || 5432} #{database[:database]}`
        if (! $?.success?) || output.nil? || output.empty?
          raise "psql failed. exit status #{$?.to_i}, output: #{output.inspect}"
        end
        output
      rescue Errno::ENOENT
        Clitopic::Helpers.output_with_bang "The local psql command could not be located"
        abort
      end
    end

    # @TODO INCLUDE THIS IN CLITOPIC
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

    # @TODO INCLUDE THIS IN CLITOPIC
    def hash_opt(opt)
      return {} if opt.nil?
      if opt.is_a?(Hash)
        hash = opt
      else
        hash = kv_parse(options[opt])
      end
      return hash
    end

    def psql_cmd
      'psql'
    end

    def version
      return @version if defined? @version
      result = exec_sql("select version();").match(/PostgreSQL (\d+\.\d+\.\d+) on/)
      fail("Unable to determine Postgres version") unless result
      @version = result[1]
    end

    def nine_two?
      return @nine_two if defined? @nine_two
      @nine_two = version.to_f >= 9.2
    end

    def pid_column
      if nine_two?
        'pid'
      else
        'procpid'
      end
    end

    def query_column
      if nine_two?
      'query'
      else
      'current_query'
      end
    end

    def parse_pg_uri(uri)
      p = URI.parse(uri)
      h = {
        database: p.path[1..-1],
        user: p.user,
        password: p.password,
        host: p.hostname || "localhost",
        uri: uri,
        port: p.port || 5432
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

    def ssl?
      options[:ssl] ? "require" : "prefer"
    end

    def database(db=nil)
      db = options[:database] if db.nil?
      uri = URI.parse(db)
      if uri.scheme == "postgres"
        parse_pg_uri(db)
      elsif databases[db]
        return databases[db]
      else
        raise Clitopic::Commands::CommandFailed.new ("No database #{db}")
      end
    end
  end
end
