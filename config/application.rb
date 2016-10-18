require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FordhamLawSearch
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.


    # Turn off include_all_helpers, it's terrible. Controller
    # will automatically include helper with matching name, others
    # if needed can be included explicitly with `helper` or `helper_method`
    # in controller.
    config.action_controller.include_all_helpers = false
  end
end
