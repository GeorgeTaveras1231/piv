describe Piv::ThorShellHelp do
  let(:thor_shell) do
    described_class.new
  end
  describe "#center_paragraph" do
    it "centers every line of a paragraph" do
      text = <<-TEXT.strip_heredoc
        hello world this is a test and here
        are some
        new lines for ya
      TEXT

      expected_text = <<-TEXT.strip_heredoc
********hello world this********
*********is a test and**********
*********here are some**********
********new lines for ya********
      TEXT

      expect(thor_shell.center_paragraph(text, 16, 32, '*')).to eq(expected_text.chomp)
    end

  end

  describe "#indent_whole_paragraph" do
    it "indents every line of a paragraph" do
      text = <<TEXT
hello world this is a test and here
are some
new lines for ya
TEXT

      expected_text = <<TEXT
  hello world this is a test and here
  are some
  new lines for ya
TEXT

      expect(thor_shell.indent_whole_paragraph(text, 2)).to eq expected_text.chomp
    end
  end
end
