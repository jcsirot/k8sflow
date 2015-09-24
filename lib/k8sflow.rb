require 'clitopic'
require 'k8sflow/version'
require 'k8sflow/cli'
require 'k8sflow/command'

Clitopic.version = K8sflow::VERSION
Clitopic.parser = Clitopic::PARSERS[:optparse]
Clitopic.commands_dir = "#{__FILE__}/k8sflow/command"

K8sflow::Run::Index.defaults = {docker_api: 'tcp://localhost:4243', envs: ['FORCE_HTTPS=true', 'RAILS_ENV=production'], repo: 'arkena/osm-backend'}
