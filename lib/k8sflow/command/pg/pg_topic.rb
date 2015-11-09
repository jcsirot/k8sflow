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
