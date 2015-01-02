RSpec::Matchers.define :exit_with_code do |expected|
  supports_block_expectations
  match do |actual|
    if actual.is_a? Proc
      begin
        actual.call
      rescue SystemExit => e
        exit_code = e.status
      end
      expected == exit_code
    else
      raise ArgumentError, "actual must be a code block for this matcher"
    end
  end
end
