
require 'clitopic/cli'
require 'k8sflow/command'
module K8sflow
  class Cli
    def self.run(args)
      Clitopic::Cli.run(args)
    end
  end
end
