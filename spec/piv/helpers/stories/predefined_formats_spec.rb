describe Piv::Helpers::Stories::PredefinedFormats do
  before do
    stub_const("#{described_class.name}::PREDEFINED_FORMATS", predefined_formats)
    test_obj.extend(described_class)
  end

  let(:predefined_formats) do
    {
      :first => 'this is a format'
    }
  end

  let(:test_obj) do
    Object.new
  end

  describe "#format_name_from_metastring" do
    it "converts a metastring id into a constant name" do
      expect(test_obj.format_name_from_metastring('%a_string%')).to eq :a_string
    end

    it "returns nil if pattern is not matched" do
      expect(test_obj.format_name_from_metastring("%not_right")).to eq nil
    end
  end

  describe "#get_format_from_metastring" do
    it "returns the format given a registered format id" do
      expect(test_obj.get_format_from_metastring('%first%')).to eq 'this is a format'
    end

    it "raises an error of format is not found" do
      expect { test_obj.get_format_from_metastring('%not_found%') }.to raise_error(KeyError)
    end

    it "allows for an alternative return value with a codeblock" do
      expect(test_obj.get_format_from_metastring('%not_found%') { 'f' }).to eq 'f'
    end
  end

end
