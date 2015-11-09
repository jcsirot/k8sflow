module K8sflow
  module Pg
    class PgTopic < Clitopic::Topic::Base
      register name: 'pg',
               description: 'Manage postgres actions'

      option :database, '-d', '--database DATABASE', '[REQUIRED] Database uri or alias', required: true
      option :ssl, "--ssl", "enable sslmode"

      option :databases, "--databases alias1=postgresql_URI,alias2=postgresql_URI2", Array, "Create database aliases"


    end
  end
end
