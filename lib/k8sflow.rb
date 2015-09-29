require 'clitopic'
require 'k8sflow/version'

Clitopic.version = K8sflow::VERSION
#Clitopic.parser = Clitopic::Parser::OptParser
Clitopic.commands_dir = "#{__FILE__}/k8sflow/command"
Clitopic.default_files = [File.join(Dir.getwd, ".k8sflow.yml"), File.join(Dir.home, ".k8sflow.yml")]


require 'k8sflow/cli'


K8sflow::Command::Run.aliases = {'c' => 'rails console', 's' => 'rails server', 'console' => "rails console", "server" => "rails server"}
