module Kernel
  if RUBY_VERSION < '2.0.0'
    def __dir__
      File.dirname(File.realpath(__FILE__))
    end
  end
end
