describe Piv::Application do
  describe "::for" do

    let(:stub_mod) do
      Module.new do
        MyHelper = Module.new do
          def a_new_method
          end

          First = Module.new do
            def nested_mod_method1
            end
          end

          Second = Module.new do
            def nested_mod_method2
            end
          end
        end
      end
    end

    before do
      stub_const 'Piv::Helpers', stub_mod
    end

    let(:runner) { double :runner }

    context "when a specified module doesnt exist in Helpers" do
      it "raises an argument error" do
        expect{ described_class.for(runner, :non_existent) }.to raise_error(ArgumentError)
      end
    end

    context "when a specified module exists in Helpers" do
      it "creates an instance of application and makes the found module's methods" do
        expect(described_class.for(runner, :my_helper)).to respond_to(:a_new_method)
      end
    end

    context "when specifying nested modules" do
      it "fetches the nested modules and extends the application instance with these mods" do
        expect(described_class.for(runner, :my_helper => [:first, :second]))
          .to respond_to(:a_new_method, :nested_mod_method1, :nested_mod_method2)
      end
    end
  end
end
