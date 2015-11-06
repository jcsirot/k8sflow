require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Ps < PgBase
      register name: 'ps',
               description: 'view active queries with execution time',
               topic: 'pg'

      option :verbose, "--verbose", "also show idle connections"

      def self.call
        sql = %Q(
    SELECT
      #{pid_column},
      #{"state," if nine_two?}
      application_name AS source,
      age(now(),xact_start) AS running_for,
      waiting,
      #{query_column} AS query
     FROM pg_stat_activity
     WHERE
       #{query_column} <> '<insufficient privilege>'
       #{
      # Apply idle-backend filter appropriate to versions and options.
      case
      when options[:verbose]
        ''
      when nine_two?
        "AND state <> 'idle'"
      else
        "AND current_query <> '<IDLE>'"
      end
       }
       AND #{pid_column} <> pg_backend_pid()
       ORDER BY query_start DESC
     )

        puts exec_sql(sql)
      end
    end

  end
end
