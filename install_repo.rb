#!/usr/bin/env ruby
#encoding: utf-8
# Adapted for the needs of Elexis by Niklaus Giger, niklaus.giger@member.fsf.org 2013
#

require "find"
require "fileutils"
require 'optparse'  # This hash will hold all of the options # parsed from the command-line by # OptionParser.
require 'pp'

VALID_VARIANTS = ['snapshot', 'beta', 'prerelease', 'release']

options = {}
repo_name = File.basename(`git config --get remote.origin.url`.chomp, '.git').gsub('-', '.')
dest = ENV['ROOT']
dest ||= "/srv/www/download.elexis.info/#{repo_name}"
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: install_repo.rb path_to_repo. Defaults to #{dest}
  or the value of the ROOT environment variable"
  options[:variant] = 'snapshot'
  opts.on('--variant variant', 'Must be one of snapshot, beta, prerelease, release. Defaults to snapshot' ) do |value|
    unless VALID_VARIANTS.index(value)
        puts optparse
        exit 1
    end
    options[:variant] = value
  end
end
optparse.parse!
repository = Dir.glob('**/target/repository')
unless repository.size == 1
  puts "Abort as no target/repository found"
  exit 1
end
repository = repository.first

variant = options[:variant]

# Variant may be overridden by value repoVariant from repo.properties file
properties = File.join(File.dirname(File.dirname(repository)), 'repo.properties')
if File.exist?(properties)
  inhalt = IO.read(properties)
  m = /^repoVariant=(.+)$/.match(inhalt)
  variant = m[1] if m && VALID_VARIANTS.index(m[1])
end

timestamp = File.mtime(repository).strftime('%Y%m%d-%H%M')
dest = ARGV[0] if ARGV[0]
published = "#{dest}/#{variant}"
before = "#{dest}/#{variant}_before_try"
backup = "#{dest}/backups/#{variant}"
puts "published #{published} dest #{dest} before #{before}"

if File.exist?(published)
  timestamp = File.mtime(published).strftime('%Y%m%d-%H%M')
  FileUtils.makedirs(backup)
  target = "#{backup}/#{timestamp}"
  FileUtils.mv(published, "#{target}", :verbose => true) unless File.exist?(target)
end
FileUtils.makedirs(File.dirname(published))
FileUtils.cp_r(repository, published, :verbose => true, :preserve => true)

