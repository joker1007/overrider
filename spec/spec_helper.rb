require "bundler/setup"
require "overrider"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:suite) do
    ObjectSpace.each_object do |obj|
      if obj.is_a?(TracePoint)
        raise "exists enabled TracePoint" if obj.enabled?
      end
    end
  end
end
