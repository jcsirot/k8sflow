require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Restore < PgBase
      register name: 'restore',
               description: 'Restore a dump to target database',
               topic: 'pg'

      option :src, "--src=file", "Dump to store"
      option :confirm, "--confirm CONFIRM", "Command line confirmation, no prompt"

      def self.call
        puts "PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_restore --port #{database[:port]} --host #{database[:host]} --username #{database[:user]}  --verbose --no-acl --no-owner -d #{database[:database]} < #{file.path}"
        confirm_command("on #{database[:host]} overwrite the database #{database[:database]}")
        exec("PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_restore --port #{database[:port]} --host #{database[:host]} --username #{database[:user]}  --verbose --no-acl --no-owner -d #{database[:database]} < #{file.path}")
      end
    end

  end
end
