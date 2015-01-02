describe Piv::Helpers::Formatter::Parser do
  let(:parser) do
    described_class.new(attribute_map)
  end

  let(:attribute_map) do
    {}
  end

  describe "#parse" do
    describe "%c( [color, background, style] )" do
      it "parses words to bash formatted meta characters" do
        expect(parser.parse("%c( red )")).to include "\e[31m"
      end
    end

    describe "%a( [attribute] )" do
      let(:attribute_map) do
        { :attr1 => "value1",
          :attr2 => "value2" }
      end

      it "parses args to attribute values" do
        arguments = "%a( attr1 )%a( attr2 )"

        expect(parser.parse(*arguments)).to include "value1value2"
      end
    end

    describe "%cA( [attribute, padd_with=' ', total_with=terminal width] )" do
      let(:attribute_map) do
        { :attr1 => "value1",
          :attr2 => "value2" }
      end

      it "centers the attribute" do
        arguments = "%cA( ' attr1 ' '*-' )"
        expect(parser.parse(*arguments)).to match(/[*-]{20,} value1 [*-]{20,}/)
      end
    end

    describe "%cP( [attribute, padd_with, total_width=terminal width], line_width=3/4 of total)" do
      let(:attribute_map) do
        {
          :attr1 => <<-DESC
hello world this is a test and here
are some
new lines for ya

          DESC
        }
      end

      let(:expected_text) do
<<TEXT
******* hello world this *******
******** is a test and *********
******** here are some *********
******* new lines for ya *******
TEXT
      end

      it "centers multiple lines" do
        arguments = "%cP( ' attr1 ' '*' 32 16 )"
        expect(parser.parse(*arguments)).to include expected_text.strip
      end
    end

    describe "%iP( [attribute, indentation, padstr] )" do

      let(:attribute_map) do
        {
          :attr1 => <<-DESC
hello world this is a test and here
are some
new lines for ya
          DESC
        }
      end

      let(:expected_text) do
<<TEXT
*****-hello world this is a test and here-
*****-are some-
*****-new lines for ya-
TEXT
end

      it "indents every line a a paragraph" do
        arguments = "%iP( -attr1- 5 * )"
        expect(parser.parse(*arguments)).to include expected_text.chomp
      end
    end
  end
end
