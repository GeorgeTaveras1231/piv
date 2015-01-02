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

        let(:global_dir) { File.join(__dir__, 'fixtures', 'piv_test') }
        let(:api_url) { "https://www.pivotaltracker.com/services/v5/" }

        let(:connection) do
          Faraday.new(api_url) do |conn|
            conn.request :json
            conn.response :json
            conn.adapter Faraday.default_adapter
          end
        end

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

        before do
          Piv::Application.global_dir = global_dir
          Piv::Application.connection = connection

          Piv::Application.for(nil).assure_globally_installed
        end

        after do
          if Dir.exist? global_dir
            FileUtils.rm_r global_dir
          end
        end


      end

    end
  end
end
