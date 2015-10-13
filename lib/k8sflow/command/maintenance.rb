module K8sflow
  module Maintenance
    class MaintenanceTopic < Clitopic::Topic::Base
      register name: 'maintenance',
      description: 'Switch application in maintenance mode'

      option :app, '-A', '--app app-backend', 'Application backend set in HAPROXY'
      option :api, '--api API_ENDPOINT', 'Endpoint to configure haproxy'
    end

    class Status < Clitopic::Command::Base
      register name: 'status',
      description: 'View maintenance status',
      topic: 'maintenance'

      def self.call
      end
    end

    class On < Clitopic::Command::Base
      register name: 'on',
      description: 'Enable maintenance mode',
      topic: 'maintenance'

      def self.call
      end
    end

    class Off < Clitopic::Command::Base
      register name: 'off',
      description: 'disable maintenance mode',
      topic: 'maintenance'

      def self.call
      end
    end
  end
end
