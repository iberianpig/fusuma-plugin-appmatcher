#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../lib/fusuma/plugin/application_matcher/bamf.rb'
require_relative '../lib/fusuma/plugin/application_matcher/version.rb'

option = {}
opt = OptionParser.new

opt.on('-l', '--list-applications',
       'List applications') do |v|
  option[:list] = v
end

opt.on('--version', 'Show version') do |v|
  option[:version] = v
end

opt.parse!(ARGV)

if option[:list]
  bamf = Fusuma::Plugin::ApplicationMatcher::Bamf.new
  application_names = bamf.fetch_applications.map { |app| bamf.find_name(app[:desktop_file]) }
  puts application_names
  return
end

if option[:version]
  puts Fusuma::Plugin::ApplicationMatcher::VERSION
  return
end

bamf = Fusuma::Plugin::ApplicationMatcher::Bamf.new
puts bamf.active_application_name
