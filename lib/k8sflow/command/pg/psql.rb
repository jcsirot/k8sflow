require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Psql < PgBase
      register name: 'psql',
               description: 'psql to the database',
               topic: 'pg'
      def self.call
        puts "PGPASSWORD=**** psql -h #{database[:host]} -U #{database[:user]} -d #{database[:database]} -p #{database[:port]} #{@arguments.join(" ")}"
        exec("PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} psql -p #{database[:port]} -h #{database[:host]} -U #{database[:user]} -d #{database[:database]} #{@arguments.join(" ")}")
      end
    end

  end
end
