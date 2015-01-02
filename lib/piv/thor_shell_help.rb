module Piv
  # this is just a patch to get thors color parsing functionality
  class ThorShellHelp < Thor::Shell::Color
    def initialize(stdout=$stdout)
      @stdout = stdout
    end

    attr_reader :stdout

    def interpret_colors(*args)
      args.map { |arg| lookup_color(arg.to_sym) }.join
    end

    def break_into_lines(text, max_width)
      lines = []
      line = []
      text.scan(/[^\s]+/).map do |match|
        if (line + [match]).join(' ').length > max_width
          # flush
          lines << line.join(' ')
          line.clear
        end
        line << match
      end
      lines << line.join(' ')
      lines
    end

    def center_paragraph(text, text_width, block_width, padstr = ' ')
      lines = break_into_lines(text, text_width)
      lines.map do |l|
        l = yield(l).to_s if block_given?

        l.center(block_width, padstr)
      end.join("\n")
    end

    def indent_whole_paragraph(text, indentation=6, padstr = ' ')
      text.scan(/^.*$/).map do |l|
        l = yield(l).to_s if block_given?
        (padstr * indentation) + l
      end.join("\n")
    end
  end
end
