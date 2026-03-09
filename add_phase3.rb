require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

lockedin_target = project.targets.find { |t| t.name == 'LockedIn' }
lockedin_group = project.main_group.groups.find { |g| g.name == 'LockedIn' || g.path == 'LockedIn' }
shared_group = lockedin_group.groups.find { |g| g.name == 'Shared' }
shared_domain_group = shared_group.groups.find { |g| g.name == 'Domain' }
shared_data_group = shared_group.groups.find { |g| g.name == 'Data' } || shared_group.new_group('Data', 'Data')

sources_build_phase = lockedin_target.source_build_phase

# Domain files
domain_files = ['CommitmentActionService.swift', 'PlanService.swift']
domain_files.each do |file_name|
  unless shared_domain_group.files.any? { |f| f.path == file_name }
    file_ref = shared_domain_group.new_file(file_name)
    sources_build_phase.add_file_reference(file_ref)
    puts "Added Domain/#{file_name}"
  end
end

# Data files
data_files = ['LegacyCommitmentWrapper.swift', 'LegacyPlanWrapper.swift']
data_files.each do |file_name|
  unless shared_data_group.files.any? { |f| f.path == file_name }
    file_ref = shared_data_group.new_file(file_name)
    sources_build_phase.add_file_reference(file_ref)
    puts "Added Data/#{file_name}"
  end
end

project.save
puts "Project saved successfully."
