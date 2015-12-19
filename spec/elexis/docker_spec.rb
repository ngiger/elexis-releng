require 'spec_helper'

describe Elexis::Docker do
  describe 'docker' do
    it 'Must be able to run docker-compose build' do
      Dir.chdir(File.expand_path(File.join(__FILE__, '..', '..', '..', 'jenkins')))
      puts Dir.pwd
      expect(system('docker-compose build')).to eq(true)
    end

    it 'Must be able to run docker-compose up' do
      Dir.chdir(File.expand_path(File.join(__FILE__, '..', '..', '..', 'jenkins')))
      puts Dir.pwd
      expect(system('docker-compose up')).to eq(true)
    end
  end
end