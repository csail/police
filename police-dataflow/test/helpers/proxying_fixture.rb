class ProxyingFixture
  # Zero arguments.
  def length; end
  
  # One argument.
  def ==(other)
    '== proxied'
  end
  
  # Reserved method proxying test.
  def !=(other)
    '!= proxied'
  end
  
  # Two arguments.
  def add(arg1, arg2)
    "#{arg1}, #{arg2}"
  end
  protected :add
  
  # Variable args.
  def route(*rest)
    if block_given?
      yield(*rest)
    else
      rest
    end
  end

  # One fixed + variable args.
  def <=>(arg1, *rest); end

  # Two fixed + variable args.
  def log(arg1, arg2, *rest); end
  private :log
  
  # Magic methods: magic_* methods return their name and args
  def method_missing(name, *args)
    if name[0, 6] == 'magic_'
      [name[6..-1]] + args
    else
      super
    end
  end
end  # class ProxyingFixture
