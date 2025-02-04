# frozen_string_literal: true

APP_STORE_CONNECT_OUTPUT_NAME = 'Simplenote-AppStore'
XCARCHIVE_PATH = File.join(OUTPUT_DIRECTORY_PATH, "#{APP_STORE_CONNECT_OUTPUT_NAME}.xcarchive")
XCARCHIVE_ZIP_PATH = File.join(OUTPUT_DIRECTORY_PATH, "#{APP_STORE_CONNECT_OUTPUT_NAME}.xcarchive.zip")

lane :build_for_app_store_connect do |fetch_code_signing: true|
  update_certs_and_profiles_app_store if fetch_code_signing

  build_app(
    scheme: 'Simplenote',
    workspace: WORKSPACE,
    configuration: 'Distribution AppStore',
    clean: true,
    export_method: 'app-store',
    # The options below might seem redundant but are currently all necessary to have predictable artifact paths to use in other lanes.
    #
    # - archive_path sets the full path for the xcarchive.
    # - output_directory and output_name set the path and basename for the ipa and dSYM.
    #
    # We could have used 'build_path: OUTPUT_DIRECTORY_PATH' for the xcarchive...
    # ...but doing so would append a timestamp and unnecessarily complicate other logic to get the path
    archive_path: XCARCHIVE_PATH,
    output_directory: OUTPUT_DIRECTORY_PATH,
    output_name: APP_STORE_CONNECT_OUTPUT_NAME
  )

  # It's convenient to have a ZIP available for things like CI uploads
  UI.message("Zipping #{XCARCHIVE_PATH} to #{XCARCHIVE_ZIP_PATH}...")
  zip(path: XCARCHIVE_PATH, output_path: XCARCHIVE_ZIP_PATH)
end

lane :upload_to_app_store_connect do |beta_release:, skip_prechecks: false, create_release: false|
  sentry_check_cli_installed unless skip_prechecks

  ipa_path = File.join(OUTPUT_DIRECTORY_PATH, "#{APP_STORE_CONNECT_OUTPUT_NAME}.ipa")
  UI.user_error!("Could not find ipa at #{ipa_path}!") unless File.exist?(ipa_path)

  dsym_path = File.join(OUTPUT_DIRECTORY_PATH, "#{APP_STORE_CONNECT_OUTPUT_NAME}.app.dSYM.zip")
  UI.user_error!("Could not find dSYM at #{dsym_path}!") unless File.exist?(ipa_path)

  UI.important("Uploading ipa at #{ipa_path} to TestFlight...")
  upload_to_testflight(
    ipa: ipa_path,
    api_key_path: APP_STORE_CONNECT_KEY_PATH,
    skip_waiting_for_build_processing: false,
    distribute_external: true,
    changelog: File.read(RELEASE_NOTES_SOURCE_PATH),
    reject_build_waiting_for_review: true,
    groups: ['Internal A8C Beta Testers', 'External Beta Testers']
  )

  UI.important("Uploading dSYM at #{dsym_path} to Sentry...")
  sentry_upload_dsym(
    dsym_path: dsym_path,
    auth_token: EnvManager.get_required_env!('SENTRY_AUTH_TOKEN'),
    org_slug: 'a8c',
    project_slug: 'simplenote-ios'
  )

  next unless create_release

  version = beta_release ? build_code_current : release_version_current
  create_github_release(
    repository: GITHUB_REPO,
    version: version,
    release_notes_file_path: RELEASE_NOTES_SOURCE_PATH,
    release_assets: XCARCHIVE_ZIP_PATH.to_s,
    prerelease: beta_release
  )
end
