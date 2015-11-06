require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Kill < PgBase
      register name: 'kill',
               description: 'kill a query',
               topic: 'pg'

      option :force, "--force", 'terminates the connection in addition to cancelling the query'

      def self.call
        output_with_bang "procpid to kill is required" unless @arguments[0] && @arguments[0].to_i != 0
        procpid = @arguments[0]
        procpid = procpid.to_i
        cmd = options[:force] ? 'pg_terminate_backend' : 'pg_cancel_backend'
        sql = %Q(SELECT #{cmd}(#{procpid});)
        puts exec_sql(sql)
      end
    end

  end
end
