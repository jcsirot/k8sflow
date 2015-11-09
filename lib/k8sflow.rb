require 'clitopic'
require 'k8sflow/version'

Clitopic.name = 'k8sflow'
Clitopic.version = K8sflow::VERSION
#Clitopic.parser = Clitopic::Parser::OptParser
Clitopic.commands_dir = "#{__FILE__}/k8sflow/command"
Clitopic.default_files = [File.join(Dir.getwd, ".k8sflow.yml"), File.join(Dir.home, ".k8sflow.yml")]

Clitopic.help_page = "https://github.com/ant31/k8sflow/wiki"
Clitopic.issue_report = "https://github.com/ant31/k8sflow/issues/new"
require 'k8sflow/cli'


K8sflow::Command::Run.aliases = {'c' => 'rails console', 's' => 'rails server', 'console' => "rails console", "server" => "rails server"}
