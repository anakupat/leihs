require 'pry'
require 'turnip/capybara'
require 'rails_helper'
require 'factory_girl'

Dir.glob("engines/procurement/spec/steps/**/*.rb") { |f| load f, true }
Dir.glob("engines/procurement/spec/factories/**/*factory.rb") { |f| load f, true }

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new app, browser: :firefox
end

Capybara.register_driver :phantomjs do |app|
  Capybara::Selenium::Driver.new app, browser: :phantomjs
end

RSpec.configure do |config|

  config.raise_error_for_unimplemented_steps = true

  config.include Rails.application.routes.url_helpers

  unless ENV['CIDER_CI_TRIAL_ID'].present?
    require 'database_cleaner'
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)

    config.before(type: :feature) do
      DatabaseCleaner.start
    end

    config.after(type: :feature) do
      DatabaseCleaner.clean
    end
  end

  config.before(type: :feature) do
    FactoryGirl.create(:setting) unless Setting.first

    Capybara.current_driver = :phantomjs
  end

  config.after(type: :feature) do
    page.driver.quit # OPTIMIZE force close browser popups
    Capybara.current_driver = Capybara.default_driver
  end
end
