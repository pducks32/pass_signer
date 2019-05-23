require "bundler/setup"
require "pass_signer"
require "pathname"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(Module.new do
    def sample_store_pass_path
      Pathname(__FILE__) + "../fixtures/StoreCard.pass/"
    end
  end)
end
