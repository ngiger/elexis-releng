require 'pp'
Repos = [
# As decided between Marco and Niklaus the elexis.3rdparty.libraries and mirror.4.elexis
# are frozen for 3.1 and copied as 3.1.0 on srv.elexis.info
# 'git@github.com:elexis/elexis.3rdparty.libraries.git',
# 'git@github.com:elexis/mirror.4.elexis.git',
  'git@github.com:elexis/elexis-3-core.git',
  'git@github.com:elexis/elexis-3-base.git',
	#  'git@github.com:ngiger/org.elexis_derivate.git',
  "https://#{@user}@gitext.medelexis.ch/medelexis-3-application.git",
  "https://#{@user}@git.medelexis.ch/medelexis-3.git",
]

