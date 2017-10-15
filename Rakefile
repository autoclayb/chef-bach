#!/usr/bin/env rake

namespace :style do
  require 'rubocop/rake_task'
  desc 'Run Ruby style checks using rubocop'

  require 'foodcritic'
  desc 'Run Chef style checks using foodcritic'
  orig_dir = Dir.pwd
  FoodCritic::Rake::LintTask.new(:chef) do |t|
    t.options = {
      progress: true,
      fail_tags: %w[correctness],
      role_path: ['./stub-environment/roles/'],
      environment_path: ['./stub-environments/environments/Test-Laptop.json']
#      cookbook_path: ['./cookbooks/'],
    }
  end

  Dir.glob('./cookbooks/*').each do |c|
    Dir.chdir(File.join(orig_dir, c))
    FoodCritic::Rake::LintTask.new(('chef' + c).to_sym) do |t|
      t.options = {
        progress: true,
        fail_tags: %w[correctness],
        role_path: ['./stub-environment/roles/*'],
        cookbook_path: c,
        environment_path: ['./stub-environments/environments/Test-Laptop.json']
      }
    end
  Dir.chdir(orig_dir)
  end

  RuboCop::RakeTask.new(:ruby) do |t|
    t.options = ['-d']
    t.fail_on_error = false
  end
end

### Clay XXX
desc "Check style violation difference"
task(:style_diff) do
  sh "ronn -w --roff man/*.ronn"
end

desc 'Run all style checks'
task style: %w(style:ruby style:chef) + \
            Dir.glob('./cookbooks/*').map { |c| 'style:chef' + c }

desc 'Clean some generated files'
task :clean do
  %w(
    **/Berksfile.lock
    .bundle
    .cache
    **/Gemfile.lock
    .kitchen
    vendor
    ../cluster
  ).each { |f| FileUtils.rm_rf(Dir.glob(f)) }
  # XXX should remove VBox VM's
end

task :default => 'style'
