task :vminfo do
  require 'police/vminfo'
  require 'yaml'

  modules = Set.new
  class_methods = {}
  instance_methods = {}
  Police::VmInfo.core_modules.sort_by(&:to_s).each do |module_object|
    methods = []
    Police::VmInfo.core_class_methods(module_object).sort_by(&:to_s).
                   each do |method|
      next unless Police::VmInfo.method_source(method) == :native
      next if method.arity == 0
      methods << method.name
    end
    unless methods.empty?
      class_methods[module_object.to_s] = methods.sort
      modules << module_object.to_s
    end

    methods = []
    Police::VmInfo.core_instance_methods(module_object).sort_by(&:to_s).
                   each do |method|
      next unless Police::VmInfo.method_source(method) == :native
      next if method.arity == 0
      methods << method.name
    end
    unless methods.empty?
      instance_methods[module_object.to_s] = methods.sort
      modules << module_object.to_s
    end
  end

  profile_path = File.expand_path(
    "../lib/police/dataflow/gate_profiles/#{Police::VmInfo.signature}",
    File.dirname(__FILE__))
  File.open(profile_path, 'w') do |f|
    f.write YAML.dump(core: modules.to_a.sort, :class => class_methods,
                      instance: instance_methods)
  end
end
