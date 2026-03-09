require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

tests_target = project.targets.find { |t| t.name == 'LockedInTests' }
tests_group = project.main_group.groups.find { |g| g.name == 'LockedInTests' || g.path == 'LockedInTests' }
tests_shared_group = tests_group.groups.find { |g| g.name == 'Shared' }
tests_shared_domain_group = tests_shared_group.groups.find { |g| g.name == 'Domain' }

tests_build_phase = tests_target.source_build_phase
file_name = 'DailyCheckInReliabilityCalculatorTests.swift'

unless tests_shared_domain_group.files.any? { |f| f.path == file_name }
  file_ref = tests_shared_domain_group.new_file(file_name)
  tests_build_phase.add_file_reference(file_ref)
  puts "Added #{file_name} to LockedInTests target"
end

project.save
puts "Project saved successfully."
