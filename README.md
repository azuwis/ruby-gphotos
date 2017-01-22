# Gphotos

Use [Selenium WebDriver](http://www.seleniumhq.org/projects/webdriver/) to ease uploading files to [Google Photos](https://photos.google.com/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gphotos'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gphotos

## Usage

Install [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/). On Debian:

    # apt-get install chromium-driver

Command line options:

    Usage: gphotos [options] file...

    Specific options:
        -e, --email=EMAIL                Set email to EMAIL
        -p, --passwd=PASSWD              Set passwd to PASSWD
        -l, --list=FILE                  Read list of files to upload from FILE

    Common options:
        -h, --help                       Show this message
        -V, --version                    Show version

Example:

    $ gphotos -e foo@gmail.com -p bar /path/to/image.jpg /path/to/video.mp4

    upload:
    /path/to/image.jpg
    /path/to/video.mp4

    done:
    2 uploaded
    0 skipped
    0 not exist

Set email and password in config file, `~/.gphotos.yml`:

    :email: foo@gmail.com
    :passwd: foo

If you use password managers like [pass](https://www.passwordstore.org/), you can use `:passwd_exec` instead:

    :passwd_exec: pass show foo@gmail.com

ChromeDriver user data(browser settings, cookies, cache) will be saved in `~/.gphotos/chromedriver`, so you don't need to login every time. If you encounter any browser related problem, remove the user data directory and retry.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/azuwis/ruby-gphotos.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

