shared_examples_for "a command that requires a current project" do
  before do
    Piv::Session.current.projects.update_all(:current => false)
  end

  it "outputs a message notifying the user that there is no current project" do
    allow_exit!
    expect { run_command }.to output(a_string_matching(/not checked out.*Run.*`piv projects checkout \(PROJECT_ID\)`.*/i)).to_stderr
  end

  it "exits with a status of 1" do
    expect { run_command }.to exit_with_code(1)
  end
end
