require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)
test_target = project.targets.find { |t| t.name == 'LockedInTests' }

# 1. Update TestSupport/CommitmentSystemStoreTestFixtures.swift
support_group = project.main_group.find_subpath(File.join('LockedInTests', 'TestSupport'), false)
if support_group
  old_fixture = support_group.files.find { |f| f.path == 'CommitmentSystemStoreTestFixtures.swift' }
  if old_fixture
    old_fixture.remove_from_project
  end
  # Only add if it doesn't already exist to avoid duplicates if run multiple times
  unless support_group.files.find { |f| f.path == 'RepositoryCommitmentServiceTestFixtures.swift' }
    new_fixture = support_group.new_file('RepositoryCommitmentServiceTestFixtures.swift')
    test_target.source_build_phase.add_file_reference(new_fixture)
  end
end

# 2. Update CommitmentSystemStore/CommitmentSystemStoreBehaviorLockTests.swift
old_group = project.main_group.find_subpath(File.join('LockedInTests', 'CommitmentSystemStore'), false)
if old_group
  old_group.name = 'RepositoryCommitmentService'
  old_group.path = 'CommitmentSystemStore' 
  
  old_test = old_group.files.find { |f| f.path == 'CommitmentSystemStoreBehaviorLockTests.swift' }
  if old_test
    old_test.remove_from_project
  end
  
  unless old_group.files.find { |f| f.path == 'RepositoryCommitmentServiceBehaviorLockTests.swift' }
    new_test = old_group.new_file('RepositoryCommitmentServiceBehaviorLockTests.swift')
    test_target.source_build_phase.add_file_reference(new_test)
  end
end

project.save
puts "Successfully updated project references for CommitmentSystem tests."
