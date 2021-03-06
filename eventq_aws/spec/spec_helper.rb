require 'aws-sdk-core'
require 'oj'
require 'eventq_base'
require 'pry'

require './lib/eventq_aws'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|

  config.before(:each) do

  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.warnings = false

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10

  config.order = :defined

  Kernel.srand config.seed
end