require 'selenium-webdriver'
require 'yaml'

module Gphotos
  class Gphotos

    def initialize(email, passwd, options = {})
      options = {:page_timeout => 20, :upload_timeout => 3600 }.merge(options)
      @driver = Selenium::WebDriver.for(:chrome)
      @driver.manage.timeouts.implicit_wait = options[:page_timeout]
      @wait = Selenium::WebDriver::Wait.new(:timeout => options[:upload_timeout])
      @cookies = File.expand_path('~/.gphotos.cookies')
      load_cookies(@cookies)
      login(email, passwd)
    end

    def load_cookies(file)
      @driver.navigate.to 'https://photos.google.com/'
      if File.exists?(file)
        YAML.load_file(file).each do |cookie|
          @driver.manage.add_cookie(cookie)
        end
      end
    end

    def login(email, passwd)
      @driver.navigate.to 'https://photos.google.com/albums'

      if @driver.title.include?('Albums')
        return
      end

      element = @driver.find_element(:id => 'Email')
      element.send_keys(email)
      element.submit

      element = @driver.find_element(:id => 'Passwd')
      element.send_keys(passwd)
      element.submit

      @driver.find_element(:css => 'input[type="file"]')
      File.write(@cookies ,@driver.manage.all_cookies.to_yaml)
    end

    def upload(files)
      element = @driver.find_element(:css => 'input[type="file"]')
      # XXX Get upload working
      element.send_keys(files[0])

      skipped = []
      result = ''
      puts 'upload:'
      files.each do |file|
        next if !File.exists?(file)
        current_result = ''
        element.send_keys(file)
        @wait.until do
          alert = @driver.find_element(:css => 'div[role="alert"]')
          begin
            current_result = alert.attribute('innerText')
          rescue Selenium::WebDriver::Error::StaleElementReferenceError
            current_result = ''
          end
          current_result != '' and result != current_result
        end

        if current_result.include?('skipped') and result.split("\n")[0] != current_result.split("\n")[0]
          skipped.push(file)
          puts "#{file} (skipped)"
        else
          puts file
        end

        result = current_result
      end
      puts
      puts 'result:'
      puts result

      if skipped.size > 0
        puts
        puts 'skipped:'
        puts skipped.join("\n")
      end
    end

    def quit
      @driver.quit
    end

  end
end
