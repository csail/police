require 'set'

module Police

module DataFlow
  # Sets up label-propagating gates around all the native methods in the VM.
  #
  # This method is idempotent, so it is safe to call it multiple times.
  def self.setup_gates

  end

# Gating logic.
module Gating
  # Sets up label-propagating gates around all the native methods in the VM.
  #
  # This method is idempotent, so it is safe to call it multiple times.
  def self.setup_gates
    return if @gates_set
    setup_gates!
    @gates_set = true
  end
  @gates_set = false

  # Sets up label-propagating gates around all the native methods in Ruby.
  #
  # @private
  # Call setup_gates instead of calling this method directly.
  def self.setup_gates!
    Police::VmInfo.named_modules do |module_object|
      Police::VmInfo.class_methods(module_object).each do |method|
        next unless Police::VmInfo.method_source(method) == :native
        gate_class_method module_object, method
      end
      Police::VmInfo.instance_methods(module_object).each do |method|
        next unless Police::VmInfo.method_source(method) == :native
        gate_instance_method module_object, method
      end
    end
  end

  # Sets up a label-propagating gate around a native method.
  #
  # @param {Module} module_object the Ruby module that owns (declared) the
  #     method that will be gated
  # @param {Method, UnboundMethod} method the method that will be gated
  def self.gate_class_method(module_object, method)
    gate_instance_method module_object.singleton_class, method
  end

  # Sets up a label-propagating gate around a native method.
  #
  # @param {Module} module_object the Ruby module that owns (declareD) the
  #     method that will be gated
  # @param {Method, UnboundMethod} method the method that will be gated
  def self.gate_instance_method(module_object, method)
    alias_name = :"__police_gated__#{method.name}"
    if module_object.public_method_defined?(alias_name) ||
        module_object.private_method_defined?(alias_name) ||
        module_object.protected_method_defined?(alias_name)
      raise RuntimeError, "#{method.inspect} was already gated"
    end

    # TODO(pwnall): finish this code
  end
end  # namespace Police::DataFlow::Guarding

end  # namespace Police::DataFlow

end  # namespace Police
