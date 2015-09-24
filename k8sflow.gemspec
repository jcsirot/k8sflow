require 'rake'
require 'date'
require File.join(File.dirname(__FILE__), 'lib/k8sflow/version')

Gem::Specification.new do |s|
  s.name = 'k8sflow'
  s.version = ::K8sflow::VERSION
  s.licenses = ['MIT']
  s.date = Date.today.to_s
  s.summary = 'Manage workflow from source to docker to kubernetes deployement'
  s.description = 'Manage workflow from source to kubernetes deployement'
  s.homepage = 'http://gitlab.com/ant31'
  s.authors = ['Antoine Legrand']
  s.email = ['ant.legrand@gmail.com']
  s.files = FileList['README.md', 'License', 'Changelog', 'lib/**/*.rb', 'lib/vendor/**/*.rb'].to_a
  s.test_files = FileList['spec/**/*.rb'].to_a
  s.executables << 'k8sflow'
  # s.add_dependency 'json', [ "~> 1.8.1" ]
  # s.add_development_dependency 'rspec'

  s.required_ruby_version = '>= 2.0.0'
end
