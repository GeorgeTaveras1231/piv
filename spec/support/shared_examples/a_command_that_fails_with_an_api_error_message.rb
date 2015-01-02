shared_examples_for "a command that fails with an API error message" do
  let(:status) { 400 }
  let(:body) do
    {
      "error" => "msg"
    }
  end

  it "prints the api errors" do
    allow_exit!
    expect { run_command }.to output(/msg/).to_stderr
  end

  it "exits with a code of 1" do
    expect { run_command }.to exit_with_code(1)
  end
end
