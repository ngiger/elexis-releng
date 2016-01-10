#!/usr/bin/env ruby
# installed git 1.8.4 via apt-get install git -t wheezy-backports und
# http://www.lyraphase.com/wp/projects/installing-latest-git-on-ubuntu-with-git-subtree-support/
# Don't use git-submodule or we will have problems when pushing/createing tags
require 'pp'
require 'fileutils'
root = File.expand_path(File.dirname(__FILE__))
@user = 'ngiger'
require File.join(root, 'repos')
system("gem install zip-zip") unless `gem list | grep zip-zip`
Timestamp = Time.new.strftime('%Y.%m.%d-%H.%M.%S')

def patch_repositories
  (Dir.glob("*/*.target")+Dir.glob('pom.xml')+Dir.glob('*p2site/update_mirror.xml')).each do |target|
    puts target
    system("git checkout #{target}")
    # replace ALL instances in a line
    exit 1 unless system("awk -i inplace '{gsub(/http:\\/\\/download.elexis.info/, \"file:///srv/download.elexis.info\")}; 1' #{target}")
    exit 1 unless system("awk -i inplace '{gsub(/https:\\/\\/download.medelexis.ch/, \"file:///srv/web/download.medelexis.ch\")}; 1' #{target}")
    system("git diff #{target}")
  end
end

Repos.each do |repo|
  Dir.chdir(root)
  dir = File.basename(repo).sub('.git','')
  unless File.directory?(dir)
    exit 1 unless system("git clone #{repo}")
  end
  Dir.chdir(File.join(root, dir))
  puts Dir.pwd
  if repo.index('medelexis')
    FileUtils.makedirs("/srv/web/download.medelexis.ch/" + dir.gsub('-','.'), verbose: true)
  else
    FileUtils.makedirs("/srv/download.elexis.info/" + dir.gsub('-','.'), verbose: true)
  end
  # next if repo.index('/elexis-3-') # skip elexis-3-core and -base
  # next unless /medelexis-3$/.match(dir) # skip elexis-3-core and -base
  patch_repositories
  case repo
    when /3rdparty/
      src = '/srv/download.elexis.info/elexis.3rdparty.libraries'
      dest = '/srv/download.elexis.info/elexis.3.3rdparty.libraries'
      FileUtils.ln_s(src, dest, verbose: true) unless File.exist?(dest)
      cmd = "mvn clean install p2:site"
    when /mirror/
      cmd = "mvn clean package"
    when /elexis-3-core/
      cmd = 'mvn clean install -Delexis.run.dbtests=true -Pall-archs'
    else
      cmd = "mvn clean install"
  end
  cmd += " -Dtycho.localArtifacts=ignore 2>&1 | tee maven-#{Timestamp}.log"
  puts cmd
  unless system(cmd)
    puts "Running #{cmd} failed!"
    exit 1
  end
  install_cmd = (Dir.glob("install_repo.sh")+Dir.glob("*/install_repo.sh"))
  unless install_cmd.size == 1
    puts "Must find exactly one install_repo.sh in #{dir}"
    exit 1
  end
  install_cmd.each do |install|
    puts install
    unless system("bash " + install + " 2>&1 | tee install-#{Timestamp}.log")
      puts "Running #{install} in #{dir} failed"
      exit 1
    end
  end
  next
end
