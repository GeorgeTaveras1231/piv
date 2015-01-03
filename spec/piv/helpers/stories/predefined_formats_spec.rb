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

  describe "#predefined_format?" do
    it "returns true if the format has been defined" do
      expect(test_obj.predefined_format?('%first%')).to be true
    end

    it "returns false if the format has not beed defined" do
      expect(test_obj.predefined_format?('%not_defined%')).to be false
    end
  end

  describe "#get_format_from_metastring" do
    it "returns the format given a registered format id" do
      expect(test_obj.get_format_from_metastring('%first%')).to eq 'this is a format'
    end
  end

end
