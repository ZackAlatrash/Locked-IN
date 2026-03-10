require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

all_files = project.main_group.recursive_children.select { |c| c.isa == 'PBXFileReference' }

plan_store_ref = all_files.find { |f| f.path && f.path.end_with?('PlanStore.swift') }
if plan_store_ref
  plan_store_ref.remove_from_project
  puts "Removed PlanStore.swift from project"
end

wrapper_ref = all_files.find { |f| f.path && f.path.end_with?('LegacyPlanWrapper.swift') }
if wrapper_ref
  wrapper_ref.remove_from_project
  puts "Removed LegacyPlanWrapper.swift from project"
end

target = project.targets.find { |t| t.name == 'LockedIn' }

# Safely find the group
locked_in_group = project.main_group.children.find { |g| g.name == 'LockedIn' || g.path == 'LockedIn' }
shared_group = locked_in_group.children.find { |g| g.name == 'Shared' || g.path == 'Shared' }
data_group = shared_group.children.find { |g| g.name == 'Data' || g.path == 'Data' }

if data_group
  # Add just the filename since the group sets the path context. This avoids double prefixing.
  new_file_ref = data_group.new_file('RepositoryPlanService.swift')
  puts "Added RepositoryPlanService.swift to project group"
  
  sources_build_phase = target.source_build_phase
  # Avoid adding it twice if already exists
  unless sources_build_phase.files_references.include?(new_file_ref)
    sources_build_phase.add_file_reference(new_file_ref)
    puts "Added RepositoryPlanService.swift to compile sources build phase"
  end
else
  puts "Could not find Shared/Data group"
end

project.save
