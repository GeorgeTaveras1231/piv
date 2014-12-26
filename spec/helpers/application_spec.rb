describe Piv::Helpers::Application do
#   let(:application_class) do
#     Class.new
#   end
#
#   let(:application) { application_class.new }
#
#   before { application_class.include described_class }
#
#   describe "#assure_globally_installed" do
#     before do
#       allow(Piv::MicroCommands::InstallGlobal).to receive(:new) { global_installer }
#     end
#
#     let(:global_installer) do
#       double(:global_installer, :done? => done?)
#     end
#
#     context "When glbal_installer is NOT done" do
#       let(:done?) { false }
#       it "runs the global installer" do
#         expect(global_installer).to receive(:run).with(:up)
#         application.assure_globally_installed
#       end
#     end
#
#     context "When glbal_installer is done" do
#       let(:done?) { true }
#       it "does nothing"
#     end
#   end
end

