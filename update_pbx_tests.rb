require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find test target
test_target = project.targets.find { |t| t.name == 'LockedInTests' }

# Replace references
support_group = project.main_group.find_subpath(File.join('LockedInTests', 'TestSupport'), false)
if support_group
  old_fixture = support_group.files.find { |f| f.path == 'PlanStoreTestFixtures.swift' }
  if old_fixture
    old_fixture.remove_from_project
  end
  new_fixture = support_group.new_file('RepositoryPlanServiceTestFixtures.swift')
  test_target.source_build_phase.add_file_reference(new_fixture)
end

plan_store_group = project.main_group.find_subpath(File.join('LockedInTests', 'PlanStore'), false)
if plan_store_group
  # Rename group logically
  plan_store_group.name = 'RepositoryPlanService'
  plan_store_group.path = 'PlanStore' # path stays the same to avoid moving folder just yet, just focusing on file

  old_test = plan_store_group.files.find { |f| f.path == 'PlanStoreBehaviorLockTests.swift' }
  if old_test
    old_test.remove_from_project
  end
  new_test = plan_store_group.new_file('RepositoryPlanServiceBehaviorLockTests.swift')
  test_target.source_build_phase.add_file_reference(new_test)
end

project.save
puts "Successfully updated test project references."
