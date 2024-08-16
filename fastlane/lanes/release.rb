# frozen_string_literal: true

# Lanes related to the Release Process (Code Freeze, Betas, Final Build, App Store Submission…)

platform :ios do
  lane :code_freeze do |skip_confirm: false|
    ensure_git_status_clean

    Fastlane::Helper::GitHelper.checkout_and_pull(DEFAULT_BRANCH)

    check_pods_references

    computed_release_branch_name = release_branch_name(release_version: release_version_next)

    message = <<~MESSAGE
      Code Freeze:
      • New release branch from #{DEFAULT_BRANCH}: #{computed_release_branch_name}

      • Current release version and build code: #{release_version_current} (#{build_code_current}).
      • New release version and build code: #{release_version_next} (#{build_code_code_freeze}).
    MESSAGE

    UI.important(message)

    UI.user_error!('Aborted by user request') unless skip_confirm || UI.confirm('Do you want to continue?')

    UI.message 'Creating release branch...'
    Fastlane::Helper::GitHelper.create_branch(computed_release_branch_name, from: DEFAULT_BRANCH)
    UI.success "Done! New release branch is: #{git_branch}"

    UI.message 'Bumping release version and build code...'
    PUBLIC_VERSION_FILE.write(
      version_short: release_version_next,
      version_long: build_code_code_freeze
    )
    UI.success "Done! New release version: #{release_version_current}. New build code: #{build_code_current}."

    commit_version_and_build_files

    new_version = release_version_current

    extract_release_notes_for_version(
      version: new_version,
      release_notes_file_path: File.join(PROJECT_ROOT_FOLDER, 'RELEASE-NOTES.txt'),
      extracted_notes_file_path: File.join(PROJECT_ROOT_FOLDER, 'Simplenote', 'Resources', 'release_notes.txt')
    )
    ios_update_release_notes(new_version: new_version)

    generate_strings_file_for_glotpress

    UI.important('Pushing changes to remote, configuring the release on GitHub, and triggering the beta build...')
    UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.") unless skip_confirm || UI.confirm('Do you want to continue?')

    push_to_git_remote(tags: false)

    copy_branch_protection(
      repository: GITHUB_REPO,
      from_branch: DEFAULT_BRANCH,
      to_branch: computed_release_branch_name
    )
    set_milestone_frozen_marker(
      repository: GITHUB_REPO,
      milestone: new_version
    )

    trigger_beta_build(branch_to_build: computed_release_branch_name)

    # TODO: Switch to working branch and open back-merge PR
  end

  lane :new_beta_release do |skip_confirm: false|
    ensure_git_status_clean
    ensure_git_branch_is_release_branch

    new_build_code = build_code_next
    UI.important <<~MESSAGE
      New beta:
      • Current build code: #{build_code_current}
      • New build code: #{new_build_code}
    MESSAGE

    UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.") unless skip_confirm || UI.confirm('Do you want to continue?')

    download_localized_strings_and_metadata_from_glotpress

    lint_localizations

    UI.message "Bumping build code to #{new_build_code}..."
    PUBLIC_VERSION_FILE.write(
      version_long: new_build_code
    )
    commit_version_and_build_files
    # Uses build_code_current let user double-check result.
    UI.success "Done! Release version: #{release_version_current}. New build code: #{build_code_current}."

    UI.important('Pushing changes to remote and triggering the beta build...')
    UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.") unless skip_confirm || UI.confirm('Do you want to continue?')

    push_to_git_remote(tags: false)

    trigger_beta_build(branch_to_build: release_branch_name)

    # TODO: Switch to working branch and open back-merge PR
  end

  lane :trigger_beta_build do |branch_to_build:|
    trigger_buildkite_release_build(branch: branch_to_build, beta: true)
  end

  lane :trigger_release_build do |branch_to_build:|
    trigger_buildkite_release_build(branch: branch_to_build, beta: false)
  end
end

def commit_version_and_build_files
  git_commit(
    path: [VERSION_FILE_PATH],
    message: 'Bump version number',
    allow_nothing_to_commit: false
  )
end

def check_pods_references
  # This will also print the result to STDOUT
  result = ios_check_beta_deps(lockfile: File.join(PROJECT_ROOT_FOLDER, 'Podfile.lock'))

  style = result[:pods].nil? || result[:pods].empty? ? 'success' : 'warning'
  message = "### Checking Internal Dependencies are all on a **stable** version\n\n#{result[:message]}"
  buildkite_annotate(context: 'pods-check', style: style, message: message) if is_ci
end

def trigger_buildkite_release_build(branch:, beta:)
  buildkite_trigger_build(
    buildkite_organization: BUILDKITE_ORGANIZATION,
    buildkite_pipeline: BUILDKITE_PIPELINE,
    branch: branch,
    environment: { BETA_RELEASE: beta },
    pipeline_file: 'release-build.yml'
  )
end
