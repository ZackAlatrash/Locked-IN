require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Add source files
lockedin_target = project.targets.find { |t| t.name == 'LockedIn' }
lockedin_group = project.main_group.groups.find { |g| g.name == 'LockedIn' || g.path == 'LockedIn' }
shared_group = lockedin_group.groups.find { |g| g.name == 'Shared' } || lockedin_group.new_group('Shared', 'Shared')
shared_domain_group = shared_group.groups.find { |g| g.name == 'Domain' } || shared_group.new_group('Domain', 'Domain')

sources_build_phase = lockedin_target.source_build_phase

['ReliabilityCalculator.swift', 'WeeklyAllowanceCalculator.swift'].each do |file_name|
  file_path = "LockedIn/Shared/Domain/#{file_name}"
  unless shared_domain_group.files.any? { |f| f.path == file_name }
    file_ref = shared_domain_group.new_file(file_name)
    sources_build_phase.add_file_reference(file_ref)
    puts "Added #{file_name} to LockedIn target"
  end
end

# Add test files
tests_target = project.targets.find { |t| t.name == 'LockedInTests' }
tests_group = project.main_group.groups.find { |g| g.name == 'LockedInTests' || g.path == 'LockedInTests' }
unless tests_group
  tests_group = project.main_group.new_group('LockedInTests', 'LockedInTests')
end

tests_shared_group = tests_group.groups.find { |g| g.name == 'Shared' } || tests_group.new_group('Shared', 'Shared')
tests_shared_domain_group = tests_shared_group.groups.find { |g| g.name == 'Domain' } || tests_shared_group.new_group('Domain', 'Domain')

tests_build_phase = tests_target.source_build_phase
['ReliabilityCalculatorTests.swift', 'WeeklyAllowanceCalculatorTests.swift'].each do |file_name|
  file_path = "LockedInTests/Shared/Domain/#{file_name}"
  unless tests_shared_domain_group.files.any? { |f| f.path == file_name }
    file_ref = tests_shared_domain_group.new_file(file_name)
    tests_build_phase.add_file_reference(file_ref)
    puts "Added #{file_name} to LockedInTests target"
  end
end

project.save
puts "Project saved successfully."
