require 'capybara/rails'

register_chrome_driver = lambda { |name, options|
  Capybara.register_driver name do |app|
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: {
        args: options[:chrome_options][:args]
      }
    )

    Capybara::Selenium::Driver.new(app,
      browser: :chrome,
      url: 'http://selenium_chrome:4444/wd/hub',
      desired_capabilities: capabilities)
  end
}

register_headless_chrome_driver = lambda { |name, options|
  Capybara.register_driver name do |app|
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: {
        w3c: false,
        args: %w[no-sandbox
                headless
                disable-infobars
                disable-popup-blocking
                disable-gpu
                window-size=1280,800] | options[:chrome_options][:args],
        prefs: {
          "download.default_directory": '/home/seluser/Downloads',
          "download.directory_upgrade": "true",
          "download.prompt_for_download": "false",
          "browser.set_download_behavior": "{ 'behavior': 'allow' }",
        }
      }
    )

    driver = Capybara::Selenium::Driver.new(app,
      browser: :chrome,
      url: 'http://selenium_chrome:4444/wd/hub',
      desired_capabilities: capabilities)
  end
}

register_chrome_driver.call(:desktop_chrome, chrome_options: { args: %w[window-size=1280,800] })
register_headless_chrome_driver.call(:desktop_headless_chrome, chrome_options: { args: %w[window-size=1280,800] })

RSpec.configure do |config|
  config.before(:example, type: :system) do |example|
    debug_with_chrome = example.metadata[:debug]
    headless_chrome = example.metadata[:js]

    if debug_with_chrome
      driven_by :desktop_chrome
      Capybara.server_host = '0.0.0.0'
      Capybara.server_port = 4000
      Capybara.app_host = 'http://runner:4000'

    elsif headless_chrome
      driven_by :desktop_headless_chrome
      Capybara.server_host = '0.0.0.0'
      Capybara.server_port = 4000
      Capybara.app_host = 'http://runner:4000'

    else
      driven_by :rack_test
    end
  end
end
