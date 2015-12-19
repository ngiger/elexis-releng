#!/usr/bin/env ruby
#encoding: utf-8
# Adapted for the needs of Elexis by Niklaus Giger, niklaus.giger@member.fsf.org 2013
#

require "find"
require "fileutils"
require 'optparse'  # This hash will hold all of the options # parsed from the command-line by # OptionParser.
require 'pp'
options = {}
repo_name = File.basename(`git config --get remote.origin.url`.chomp, '.git').gsub('-', '.')
dest = ENV['ROOT']
dest ||= "/srv/www/download.elexis.info/#{repo_name}"
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: install_repo.rb path_to_repo. Defaults to #{dest}
  or the value of the ROOT environment variable"
  options[:variant] = 'snapshot'
  opts.on('--variant', 'Must be one of snapshot, beta, prerelease, release. Defaults to snapshot' ) do |value|
    unless ['snapshot', 'beta', 'prerelease', 'release'].index(value)
        puts optparse
        exit 1
    end
    options[:variant] = value
  end
  options[:try] = false
  opts.on('--try', 'Move actual snapshot to snapshot_before_try' ) do
    options[:try] = true
  end
  options[:install] = false
  opts.on('--install', 'Move the snapshot_before_try to backup directory' ) do
    options[:install] = true
  end
  options[:revert] = false
  opts.on('--revert', 'Revert to snapshot_before_try' ) do
    options[:revert] = true
  end
end
optparse.parse!
if ARGV.size > 1 || (options[:install] == false &&
                     options[:revert] == false &&
                     options[:try] == false)
  puts optparse
  exit 3
end
repository = Dir.glob('**/target/repository')
unless repository.size == 1
  puts "Abort as no target/repository found"
  exit 1
end
repository = repository.first
timestamp = File.mtime(repository).strftime('%Y%m%d-%H%M')
dest = ARGV[0] if ARGV[0]
published = "#{dest}/#{options[:variant]}"
before = "#{dest}/#{options[:variant]}_before_try"
puts "published #{published} dest #{dest} before #{before}"
if options[:try]
  FileUtils.mv(published, before, :verbose => true) unless File.exist?(before)
  FileUtils.cp_r(repository, published, :verbose => true, :preserve => true)
  exit 0
end
backup = "#{dest}/backups/#{options[:variant]}"
if options[:revert]
  unless File.exist?(before)
    puts "Cannot revert as #{before} not found.\n   Maybe your are lucky and find an old version in #{backup}"
    exit 3
  end
  FileUtils.rm_rf(published, :verbose => true, :preserve => true)
  FileUtils.mv(before, published, :verbose => true) unless File.exist?(before)
  exit 0
end
if options[:install]
  unless File.exist?(before)
    puts "Nothing to do. No #{before} found"
    exit 0
  end
  timestamp = File.mtime(before).strftime('%Y%m%d-%H%M')
  FileUtils.makedirs(backup)
  FileUtils.mv(before, "#{backup}/#{timestamp}", :verbose => true) if File.exist?(before)
end
