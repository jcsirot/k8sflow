require 'clitopic'
require 'k8sflow/version'
require 'k8sflow/cli'
require 'k8sflow/command'

Clitopic.version = K8sflow::VERSION
Clitopic.parser = Clitopic::Parser::OptParser
Clitopic.commands_dir = "#{__FILE__}/k8sflow/command"
Clitopic.default_files = [File.join(Dir.getwd, ".k8sflow.yml"), File.join(Dir.home, ".k8sflow.yml")]

K8sflow::Run::Index.shortcuts = {'c' => 'rails console', 's' => 'rails server', 'console' => "rails console", "server" => "rails server"}
