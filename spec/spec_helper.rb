$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'elexis/releng'
require 'page-object'
require "watir-webdriver/wait"

DOCKER_DATA='/opt/docker-data-containers/jenkins-test'
JENKINS_URL='http://localhost:8081'

DownloadDir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'downloads'))

begin
  require 'pry'
rescue LoadError
  # ignore error for Travis-CI
end

def setup_browser
  return if @browser
  FileUtils.makedirs(DownloadDir)
  puts "Setting upd default profile for firefox"
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['browser.download.dir'] = DownloadDir
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.alwaysAsk.force'] = false
  profile['browser.helperApps.neverAsk.saveToDisk'] = "application/zip;application/octet-stream;application/x-zip;application/x-zip-compressed;text/csv;test/semicolon-separated-values"
  @browser = Watir::Browser.new :firefox, :profile => profile
  @browser.goto JENKINS_URL
  sleep(1.5)
end

def verify_jar_version(branch='master', variant='snapshot', job='release')
  root = File.join(DOCKER_DATA, 'jobs', job, 'workspace')
  expect(File.exist?(root)).to eq true
  ['elexis-3-core', 'elexis-3-base', 'medelexis-3-application'].each do |project|
    project_root = File.join(DOCKER_DATA, 'jobs', project, 'branches', branch, 'workspace')
    puts "Checking versions of jar files in #{project_root}"
    jars = Dir.glob("#{project_root}/**/*.jar")
    matching_jars = []
    jars.each do |jar|
      next if /SNAPSHOT/i.match(jar)
      short_name = File.basename(jar)
      next unless /elexis|medevit/.match(short_name)
      # Skip file not generated today
      next if File.atime(jar) < Date.today.to_time
      version = /_\d\.\d\.\d\.a\d{8}/.match(short_name)
      unless version
        puts "Invalid version for #{jar}"
      end
      expect(version).not_to be nil
      matching_jars << short_name
    end
    expect(matching_jars.size).to be >= 3
  end
end

def verify_repo_properties(branch='master', variant='snapshot', job='release')
  root = File.join(DOCKER_DATA, 'jobs', job, 'workspace')
  puts "Checking repo.properties files in #{root}"
  expect(File.exist?(root)).to eq true
  files = Dir.glob("#{root}/**/repo.properties")
  expect(files.size).to be >= 2
  files.each do |file|
    inhalt = IO.read(file)
    toConvert = {
      'repoVariant' => 'repo_variant',
      'repoName' => 'repo_name',
      'repoDescription' => 'repo_description',
      'projectVersion' => 'versionFromPomViaGroovy',
      'version' => 'unqualifiedVersion',
      'qualifier' => 'buildQualifier',
      'projectName' => 'project_name',
    }.each do |key, value|
      m = /#{value}/i.match(inhalt)
      if m
        puts "Found unexepted #{value} in #{file}. Content was:\n#{inhalt}"
      end
      expect(m).to be nil
    end
    puts inhalt
  end
end


def verify_p2_inf(branch='master', variant='snapshot', job='release')
  ['elexis-3-core'].each do |project|
    root = File.join(DOCKER_DATA, 'jobs', project, 'branches', branch, 'workspace')
    puts "Checking p2.inf files in #{root}"
    expect(File.exist?(root)).to eq true
    files = Dir.glob("#{root}/**/*p2.inf", File::FNM_CASEFOLD)
    good_p2_inf = []
    files.each do |file|
      # Skip file not generated today
      next if File.atime(file) < Date.today.to_time
      # puts "file #{file} #{File.atime(file)}"
      inhalt = IO.read(file)
      #   addRepository(type:0,location:http${#58}//download.elexis.info/elexis.3.base/repo_variant,name:Elexis 3 Base repo_variant");\
      toConvert = {
        'repo_variant' => variant,
      }.each do |key, value|
        m1 = /#{key}/i.match(inhalt)
        if m1
          puts "m1: Found unexepted #{key} in #{file} Content was:\n#{inhalt}"
        end
        expect(m1).to be nil
        m2 = /#{value}/i.match(inhalt)
        unless m2
          puts "m2: Found unexepted #{value} in #{file} Content was:\n#{inhalt}"
        end
        expect(m2).not_to be nil
        good_p2_inf << file
      end
    end
    expect(good_p2_inf.size).to be >= 1
  end
end
