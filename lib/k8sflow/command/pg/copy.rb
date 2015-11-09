require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Copy < PgBase
      register name: 'copy',
               description: 'Copy a source database to a Target database',
               topic: 'pg'

      option :source, "--source=database", "source database", required: true
      option :ssl, "--ssl", "enable sslmode"
      option :confirm, "--confirm CONFIRM", "Command line confirmation, no prompt"

      def self.call
        source_db = database(options[:source])
        puts "env PGSSLMODE=#{ssl?} PGPASSWORD=#{source_db[:password]} pg_dump --host #{source_db[:host]}  --port #{source_db[:port]} --username #{source_db[:user]}  --verbose -Z 0 --clean --format=c --no-owner --no-acl  -d #{source_db[:database]} | env PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_restore --port #{database[:port]}--host #{database[:host]} --username #{database[:user]}  --verbose --no-acl --no-owner -d #{database[:database]}"
        confirm_command("on #{database[:host]} overwrite the database #{database[:database]}")

        exec("env PGSSLMODE=#{ssl?} PGPASSWORD=#{source_db[:password]} pg_dump --host #{source_db[:host]}  --port #{source_db[:port]} --username #{source_db[:user]}  --verbose -Z 0 --clean --format=c --no-owner --no-acl -d #{source_db[:database]} | env PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_restore --port #{database[:port]} --host #{database[:host]} --username #{database[:user]}  --verbose --no-acl --no-owner -d #{database[:database]}")
      end
    end

  end
end
