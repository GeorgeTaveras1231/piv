module Piv
  module Specs
    module CommandTestHelpers
      extend ActiveSupport::Concern

      MACROS = [:allow_exit, :dont_silence_stream]

      MACROS.each do |macro|
        instance_var = "@_#{macro}"
        define_method("#{macro}!") { instance_variable_set(instance_var, true) }
        define_method("#{macro}?") { instance_variable_get(instance_var) }
      end

      def prompter
        Thor::LineEditor
      end

      def ask(*with)
        case with.length
        when 0
          receive(:readline)
        when 1
          receive(:readline).with(*with, anything)
        else
          receive(:readline).with(*with)
        end
      end

      included do
        WebMock.disable_net_connect!

        let(:current_session) do
          Piv::Session.current
        end

        let(:current_project) do
          current_session.projects.where(:current => true).first
        end

        let(:run_command) do
          command_proc = -> do
            if allow_exit?
              begin
                described_class.start(argv)
              rescue SystemExit
              end
            else
              described_class.start(argv)
            end
          end

          if dont_silence_stream?
            command_proc.call
          else
            silence_stream($stdout, &command_proc)
          end
        end
      end

    end
  end
end
