# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "police-dataflow"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Costan"]
  s.date = "2013-05-08"
  s.description = "Pure Ruby implementtion of data flow label propagation."
  s.email = "victor@costan.us"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "lib/police-dataflow.rb",
    "lib/police/dataflow.rb",
    "lib/police/dataflow/core_extensions.rb",
    "lib/police/dataflow/gate_profiles/ruby1.9.3",
    "lib/police/dataflow/gating.rb",
    "lib/police/dataflow/label.rb",
    "lib/police/dataflow/labeling.rb",
    "lib/police/dataflow/proxies.rb",
    "lib/police/dataflow/proxy_base.rb",
    "lib/police/dataflow/proxy_numeric.rb",
    "lib/police/dataflow/proxying.rb",
    "police-dataflow.gemspec",
    "tasks/info.rake",
    "test/dataflow/core_extensions_test.rb",
    "test/dataflow/labeling_test.rb",
    "test/dataflow/proxies_test.rb",
    "test/dataflow/proxy_base_test.rb",
    "test/dataflow/proxy_numeric_test.rb",
    "test/dataflow/proxying_test.rb",
    "test/helper.rb",
    "test/helpers/auto_flow_fixture.rb",
    "test/helpers/no_flow_fixture.rb",
    "test/helpers/proxying_fixture.rb"
  ]
  s.homepage = "http://github.com/csail/police"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.0"
  s.summary = "Data flow label propagation"
end

