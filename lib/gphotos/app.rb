require 'gphotos'
require 'optparse'
require 'ostruct'
require 'yaml'

module Gphotos
  class App

    def self.parse(args)
      options = OpenStruct.new

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] file..."
        opts.separator "\nSpecific options:"

        opts.on("-eEMAIL", "--email=EMAIL", "Set email to EMAIL") do |o|
          options.email = o
        end

        opts.on("-pPASSWD", "--passwd=PASSWD", "Set passwd to PASSWD") do |o|
          options.passwd = o
        end

        opts.on("-lFILE", "--list=FILE", "Read list of files to upload from FILE") do |o|
          options.list = o
        end

        opts.separator "\nCommon options:"

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end

        opts.on_tail('-V', '--version', 'Show version') do
          puts VERSION
          exit
        end
      end

      begin
        opt_parser.parse!(args)
      rescue OptionParser::InvalidOption
        puts opt_parser
        exit
      end

      if args.size == 0 and !options.list
        puts opt_parser
        exit
      end

      options
    end

    def self.load_config(file)
      full_path = File.expand_path(file)
      if File.exists?(full_path)
        YAML.load_file(full_path)
      else
        {}
      end
    end

    def initialize(args)
      options = self.class.parse(args)
      config = self.class.load_config('~/.gphotos/config.yml')
      @options = OpenStruct.new(config.merge(options.to_h))
    end

    def run
      files = []
      files.concat(ARGV)
      if @options.list
        files.concat(open(@options.list).read.split("\n"))
      end

      gphotos = Gphotos.new(@options.email, @options.passwd, @options.passwd_exec)

      puts "upload(#{files.size}):"
      uploaded, skipped, not_exist = gphotos.upload(files) do |file, status|
        case status
        when :uploading
          print "#{file} ..."
        when :skipped, :not_exist
          puts "\b\b\b(#{status})"
        when :uploaded
          puts "\b\b\b   "
        end
      end

      if skipped.size > 0
        puts
        puts 'skipped:'
        puts skipped.join("\n")
      end

      if not_exist.size > 0
        puts
        puts 'not_exist:'
        puts not_exist.join("\n")
      end

      puts
      puts 'done:'
      puts "#{uploaded.size} uploaded"
      puts "#{skipped.size} skipped" if skipped.size > 0
      puts "#{not_exist.size} not exist" if not_exist.size > 0

      gphotos.quit
    end

  end
end
