require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class KillAll < PgBase
      register name: 'killall',
               description: 'terminates ALL connections',
               topic: 'pg'


      def self.call
        sql = %Q(
      SELECT pg_terminate_backend(#{pid_column})
      FROM pg_stat_activity
      WHERE #{pid_column} <> pg_backend_pid()
      AND #{query_column} <> '<insufficient privilege>'
    )

        puts exec_sql(sql)
      end
    end

  end
end
