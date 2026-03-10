require 'xcodeproj'
require 'fileutils'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Delete physical legacy file
legacy_file = 'LockedIn/Application/CommitmentSystemStore.swift'
if File.exist?(legacy_file)
  File.delete(legacy_file)
  puts "Deleted physical file: #{legacy_file}"
end

# 2. Remove legacy file reference from Xcode
all_files = project.main_group.recursive_children.select { |c| c.isa == 'PBXFileReference' }
commit_ref = all_files.find { |f| f.path == 'CommitmentSystemStore.swift' || (f.path && f.path.end_with?('CommitmentSystemStore.swift')) }

if commit_ref
  commit_ref.remove_from_project
  puts "Removed CommitmentSystemStore.swift from Xcode project"
end

# 3. Add new file to Shared/Data group
locked_in = project.main_group.groups.find { |g| g.name == 'LockedIn' || g.path == 'LockedIn' }
shared = locked_in.groups.find { |g| g.name == 'Shared' }
shared_data = shared.groups.find { |g| g.name == 'Data' }

# Assuming physical file already exists at 'LockedIn/Shared/Data/RepositoryCommitmentService.swift'
new_ref = shared_data.new_file('LockedIn/Shared/Data/RepositoryCommitmentService.swift')

# 4. Add to build phase
target = project.targets.find { |t| t.name == 'LockedIn' } || project.targets.first
target.source_build_phase.add_file_reference(new_ref)
puts "Added RepositoryCommitmentService.swift to Xcode project"

project.save
puts "Project saved successfully."
