require 'spec_helper'

# Here we classify the possible combinations of branches / variants
describe Elexis::Releng do
  combinations_2_fail = [
    ['release', 'snapshot'],
    ['master',  'prerelease'],
    ['master',  'release'],
    ]

  combinations_2_succeed = [
    ['master',  'snapshot'],
    ['master',  'beta'],
    ['release', 'beta'],      # eg. 3.1-release
    ['release', 'prerelease'],
    ['release', 'release'],
    ]
  combinations_2_succeed = [    ['master',  'beta'], ] # if false # comment out for debugging a single

  it 'has a version number' do
    expect(Elexis::Releng::VERSION).not_to be nil
  end

  before :all do
    setup_browser
  end

  after :all do
    @browser.close
  end

  combinations_2_succeed.each do |comb|
    branch = comb[0]
    variant = comb[1]
    describe "jenkins branch #{branch} and variant #{variant}" do
      before :all do
        puts "Running job  #{branch} #{variant}"
        startTime = Time.now
        expect(run_job(branch, variant)).to eq true
        @diffSeconds = (Time.now-startTime).to_i
      end

      it "should have a correct version in all jars" do
        # it is impossible to finish a real build in less than 10 second
        verify_jar_version if @diffSeconds > 10
      end

      it "should have a correct version in all *p2.inf files" do
        verify_p2_inf if @diffSeconds > 10
      end

      it "should have a correct version in all repo.properties" do
        verify_repo_properties if @diffSeconds > 10
      end
    end
  end

  combinations_2_fail.each do |comb|
    branch = comb[0]
    variant = comb[1]
    describe "jenkins with branch #{branch} and variant #{variant}" do
      it "should fail fast" do
        startTime = Time.now
        expect(run_job(branch, variant)).to eq false
        expect((Time.now-startTime).to_i).to be < 10
      end
    end
  end
end

def enable_auto_refresh
  auto_refresh = /enable auto refresh/i
  @browser.link(:text => auto_refresh).click if @browser.link(:text => auto_refresh).exist?
end

def proceed_if_paused_for_input
  enable_auto_refresh
  paused = /paused for input/i
  @browser.link(:text => paused).click if @browser.link(:text => paused).exist?
  proceed = /proceed/i
  @browser.button(:text => proceed).click if @browser.button(:text => proceed).exist?
end

def abort_job_if_already_running
  enable_auto_refresh
  stop = /icon-stop/
  return unless @browser.image(:class_name => stop).exist?
  @browser.image(:class_name => stop).click
end

def run_job(branch='master', variant='snapshot', name='release', maxWait = 300)
  puts "Start job #{name} with timeout of #{maxWait} seconds"
  enable_auto_refresh
  @browser.goto "#{JENKINS_URL}/job/#{name}"
  @browser.link(:text => /Build with/).click

  abort_job_if_already_running

  # saved old build number
  old_nr =  @browser.link(:text => /\d+/).exist? ?  @browser.link(:text => /\d+/).text : '1'

  # fill in values for branch and variant
  branch_list = @browser.select_list(:text => /master/)
  branch_list.select(branch)
  variant_list= @browser.select_list(:text => /snapshot/)
  variant_list.select(variant)

  old_nr = old_nr.sub('#', '').to_i
  @browser.button(:text => 'Build').click
  new_nr =  old_nr + 1
  puts "New job nr is #{new_nr}"
  @browser.link(:text => /##{new_nr}/).wait_until_present
  @browser.link(:text => /##{new_nr}/).click
  startTime = Time.now
  build_url = "#{JENKINS_URL}/job/#{name}/#{new_nr}"
  while true
    diffSeconds = (Time.now-startTime).to_i
    # puts "diffSeconds #{diffSeconds} maxWait #{maxWait} #{@browser.url}"
    @browser.goto build_url
    red  = @browser.image(:class => /icon-red /).exist?
    anim  = @browser.image(:class => /icon-.*-anim/).exist?
    blue = @browser.image(:class => /icon-blue/).exist?
    url_okay = @browser.url.chomp('/') == build_url
    puts "red #{red} blue #{blue} anim #{anim} #{@browser.url} == #{build_url} #{url_okay}"
    if red && !anim && url_okay
      puts "Build #{build_url} failed after #{diffSeconds}"
      return false
    end
    if blue && url_okay
      puts "Build #{build_url} passed after #{diffSeconds}"
      return true
    end
    proceed_if_paused_for_input
    if diffSeconds > maxWait
      msg = "Build timeout of #{maxWait} exceeded"
      return false
    end
    sleep(1)
  end
  return false
end
