$:.unshift(File.dirname(__FILE__)+"/lib")
require 'subcommand'
require 'rim/file_logger'
require 'rim/command/sync'
require 'rim/command/upload'
require 'rim/command/status'
require 'rim/command/info'
require 'rim/git'
require 'rim/rim_exception'
require 'rim/version'
require 'tmpdir'

require 'amazing_print'
require 'byebug'

include Subcommands

# -C option was added in 1.8.5
# --ignore-removal was added in 1.8.3
MinimumGitVersion = "1.8.5"

logger = RIM::FileLogger.new($stdout, File.join(Dir.tmpdir, "rim", Time.now().strftime("rim_%Y%m%d-%H%M%S-%L.log")))
logger.level = Logger::INFO
logger.formatter = proc do |severity, time, progname, msg|
  if severity == "INFO"
    "#{msg}\n"
  else
    "#{severity}: #{msg}\n"
  end
end

RIM::GitSession.logger = logger

RIM::git_session(".") do |s|
  begin
    version = s.git_version
    if version
      cmp_str = lambda {|v| v.split(".").collect{|p| p.rjust(10)}.join}
      if cmp_str.call(version) < cmp_str.call(MinimumGitVersion)
        logger.info "Rim needs git version #{MinimumGitVersion} or higher"
        logger.info "Please update git from http://git-scm.com/"
        exit(1)
      end
    else
      # version unknown, don't complain
    end
  rescue RIM::GitException
    logger.info "It seems git is not installed or it's not in your path"
    logger.info "Please update your path or find git at http://git-scm.com/"
    exit(1)
  end
end

prog_info = "rim, version #{RIM::Version::Version}, Copyright (c) 2015, esrlabs.com"

global_options do |opts|
  opts.banner = prog_info
  opts.separator ""
  opts.separator "Usage: [<options>] rim <command> [<args>]"
  opts.on("-v","--version", "Print version info") do
    logger.info prog_info
    exit
  end
  opts.on("-l LOGLEVEL", [:debug, :info, :warn, :error, :fatal], "log level",
    "one of [debug, info, warn, error, fatal]") do |v|
    logger.level = Logger.const_get(v.upcase)
  end
end

commands = {}
add_help_option
ObjectSpace.each_object(Class).select{|clazz| clazz < RIM::Command::Command }.each do |cmdclazz|
  name = cmdclazz.name.to_s.downcase.split("::").last
  command name do |opts|
    cmd = cmdclazz.new(opts) 
    commands[name] = cmd;
  end
end
# args = %w[upload test]
# args = %w[sync -a -u https://github.com/sudeeptarlekar/r-rim -r master Änderungen]
# args = %w[sync -a -r main Änderungen]
args = %w[info]
# args = %w[status -w 02f21f8603d7fc65ec3c02cf14b39661868c7b64]
# args = %w[clean tmp]
# args = %w[status 176c52360956ed29a7a85e140e768f067446e3e0..287e19c9f997f1e335d1fae02ab9ba48e634c8e2]
# args = %w[status e592582fdb02b06d62ca766cb7b11e25dc9d9a2e..f389c4e49b14efa2640dbb0149255fa1f13b7db8]
# args = %w[info]
ARGV.unshift(*args) if ARGV.empty?
begin
  cmdname = opt_parse()
  if cmdname
    cmd = commands[cmdname]
    cmd.logger = logger
    begin
      cmd.invoke()
    rescue RIM::RimException => e
      e.messages.each do |m|
        logger.error(m)
      end
      exit(1)
    end
  end
rescue OptionParser::InvalidOption => e
  logger.error(e.message)  
  exit(1)
end
