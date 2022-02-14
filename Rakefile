# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "bump"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require "github_changelog_generator/task"

desc "bump version and generate CHANGELOG with the version"
task :bump, :type do |_, args|
  label = args[:type]
  unless %w[major minor patch pre].include?(label)
    raise "Usage: rake bump[LABEL] (LABEL: ['major', 'minor', 'patch', 'pre'])"
  end

  next_version = Bump::Bump.next_version(label)

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.user = "iberianpig"
    config.project = "fusuma-plugin-appmatcher"
    config.future_release = next_version
  end

  Rake::Task[:changelog].execute

  `git add CHANGELOG.md`

  Bump::Bump.run(label)
end

desc "Create and Push tag"
task :release_tag do
  Rake::Task["release:source_control_push"].invoke
end
