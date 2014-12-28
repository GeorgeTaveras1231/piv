module Piv
  # this is just a patch to get thors color parsing functionality
  class ColorParser < Thor::Shell::Color
    def self.parse(*args)
      new.parse(*args)
    end

    def parse(*args)
      args.map { |arg| lookup_color(arg.to_sym) }.join
    end
  end
end
