shared_examples_for "a command that requires an active session" do
  before do
    Piv::Session.destroy_all
  end

  it "exits with a status of 1" do
    expect { run_command }.to exit_with_code(1)
  end

  it "warns the user to login" do
    allow_exit!
    expect { run_command }.to output(/no session.*run `piv login`/i).to_stderr
  end
end
