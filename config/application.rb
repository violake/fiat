require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "csv"
require "yaml"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fiat
  class Application < Rails::Application

    filename = Rails.root.join('config', "application.yml")
    if File.exist?(filename)
      appconf = YAML.load_file(File.new(filename))
      appconf[ENV['RAILS_ENV']].each do |key, value|
        value = value.join "," if value.is_a? Array
        ENV[key] = value
      end
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.cache_store = :redis_store, ENV['REDIS_URL']
    config.session_store :redis_store, :key => ENV['SESSION_KEY'], :expire_after => ENV['SESSION_EXPIRE'].to_i.minutes

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
