module Kernel
  if RUBY_VERSION < '2.0.0'
    def __dir__
      file_caller = caller.first.split(':').first
      File.dirname(File.realpath(file_caller))
    end
  end
end
