require 'selenium-webdriver'

module Gphotos
  class Gphotos

    def initialize(email, passwd, passwd_exec, options = {})
      options = {:page_timeout => 20, :upload_timeout => 7200 }.merge(options)
      user_data_dir = File.expand_path('~/.gphotos/chromedriver')
      prefs = {"profile" => {"managed_default_content_settings" => {"images" => 2}}}
      @driver = Selenium::WebDriver.for(:chrome, :args => ["--user-data-dir=#{user_data_dir}"], :prefs => prefs)
      @driver.manage.timeouts.implicit_wait = options[:page_timeout]
      @wait = Selenium::WebDriver::Wait.new(:timeout => 3)
      @wait_upload = Selenium::WebDriver::Wait.new(:timeout => options[:upload_timeout])
      @workaround_applied = false
      login(email, passwd, passwd_exec)
    end

    def login(email, passwd, passwd_exec)
      @driver.navigate.to 'https://photos.google.com/albums'

      if @driver.title.include?('Albums')
        return
      end

      element = nil

      begin
        @wait.until do
          element = @driver.find_element(:css => 'input[type="email"]')
          element.displayed?
        end
      rescue Selenium::WebDriver::Error::TimeOutError
      else
        element.send_keys(email + "\n")
      end

      if !passwd and passwd_exec
        passwd = %x{#{passwd_exec}}.strip
      end

      @wait.until do
        element = @driver.find_element(:css => 'input[type="password"]')
        element.displayed?
      end
      element.send_keys(passwd + "\n")

      @driver.find_element(:css => 'input[type="file"]')
    end

    def upload(files, &block)
      element = @driver.find_element(:css => 'input[type="file"]')
      if !@workaround_applied
        # XXX Get upload working
        element.send_keys(Dir.tmpdir)
        @workaround_applied = true
      end

      uploaded = []
      skipped = []
      not_exist = []
      result = ''
      files.each do |file|
        block.call(file, :uploading)
        full_path = File.expand_path(file)
        if !File.file?(full_path)
          not_exist.push(file)
          block.call(file, :not_exist)
          next
        end
        current_result = ''
        element.send_keys(full_path)
        @wait_upload.until do
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
      [uploaded, skipped, not_exist]
    end

    def quit
      @driver.quit
    end

  end
end
