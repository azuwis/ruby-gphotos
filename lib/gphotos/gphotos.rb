require 'selenium-webdriver'
require 'yaml'

module Gphotos
  class Gphotos

    def initialize(email, passwd, passwd_exec, options = {})
      options = {:page_timeout => 20, :upload_timeout => 3600 }.merge(options)
      @driver = Selenium::WebDriver.for(:chrome)
      @driver.manage.timeouts.implicit_wait = options[:page_timeout]
      @wait = Selenium::WebDriver::Wait.new(:timeout => options[:upload_timeout])
      @cookies = File.expand_path('~/.gphotos.cookies')
      load_cookies(@cookies)
      login(email, passwd, passwd_exec)
    end

    def load_cookies(file)
      @driver.navigate.to 'https://photos.google.com/'
      if File.exists?(file)
        YAML.load_file(file).each do |cookie|
          @driver.manage.add_cookie(cookie)
        end
      end
    end

    def login(email, passwd, passwd_exec)
      @driver.navigate.to 'https://photos.google.com/albums'

      if @driver.title.include?('Albums')
        return
      end

      element = @driver.find_element(:id => 'Email')
      element.send_keys(email)
      element.submit

      if !passwd and passwd_exec
        passwd = %x{#{passwd_exec}}.strip
      end

      element = @driver.find_element(:id => 'Passwd')
      element.send_keys(passwd)
      element.submit

      @driver.find_element(:css => 'input[type="file"]')
      File.write(@cookies ,@driver.manage.all_cookies.to_yaml)
    end

    def upload(files, &block)
      element = @driver.find_element(:css => 'input[type="file"]')
      # XXX Get upload working
      element.send_keys(files[0])

      uploaded = []
      skipped = []
      result = ''
      files.each do |file|
        if !File.exists?(file)
          block.call(file, :not_exist)
          next
        end
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
          block.call(file, :skipped)
        else
          uploaded.push(file)
          block.call(file, :uploaded)
        end

        result = current_result
      end
      [uploaded, skipped]
    end

    def quit
      @driver.quit
    end

  end
end
