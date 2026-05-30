# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'


project 'Yippy', {
  'Debug' => :debug,
  'Release' => :release,
  'Beta Debug' => :debug,
  'Beta Release' => :release,
  'XCTest' => :debug
}

inhibit_all_warnings!

target 'Yippy' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for Yippy
    pod 'Default'
    pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'

    target 'YippyTests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end

    target 'YippyUITests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['ARCHS'] = '$(ARCHS_STANDARD)'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['EXCLUDED_ARCHS'] = ''
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
    end

    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ARCHS'] = '$(ARCHS_STANDARD)'
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['EXCLUDED_ARCHS'] = ''
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
            config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
            config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
        end
    end

    login_service_kit = 'Pods/LoginServiceKit/Lib/LoginServiceKit/LoginServiceKit.swift'
    if File.exist?(login_service_kit)
        source = File.read(login_service_kit)
        source = source.gsub(
            'let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()',
            "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return false }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()"
        )
        source = source.sub(
            "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return false }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }",
            "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return nil }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()\n        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }"
        )
        File.write(login_service_kit, source)
    end

    rx_cocoa_headers = [
        'Pods/RxCocoa/RxCocoa/RxCocoa.h',
        'Pods/RxCocoa/RxCocoa/Runtime/include/RxCocoaRuntime.h',
        'Pods/Target Support Files/RxCocoa/RxCocoa-umbrella.h'
    ]
    rx_cocoa_header_imports = {
        '#import "RxCocoaRuntime.h"' => '#import <RxCocoa/RxCocoaRuntime.h>',
        '#import "_RX.h"' => '#import <RxCocoa/_RX.h>',
        '#import "_RXDelegateProxy.h"' => '#import <RxCocoa/_RXDelegateProxy.h>',
        '#import "_RXKVOObserver.h"' => '#import <RxCocoa/_RXKVOObserver.h>',
        '#import "_RXObjCRuntime.h"' => '#import <RxCocoa/_RXObjCRuntime.h>',
        '#import "RxCocoa.h"' => '#import <RxCocoa/RxCocoa.h>'
    }
    rx_cocoa_headers.each do |header|
        next unless File.exist?(header)

        source = File.read(header)
        rx_cocoa_header_imports.each do |quoted_import, framework_import|
            source = source.gsub(quoted_import, framework_import)
        end
        File.write(header, source)
    end

    Dir['Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh'].each do |frameworks_script|
        source = File.read(frameworks_script)
        source = source.gsub(
            "install_framework()\n{\n  if [ -r \"${BUILT_PRODUCTS_DIR}/$1\" ]; then\n    local source=\"${BUILT_PRODUCTS_DIR}/$1\"\n  elif [ -r \"${BUILT_PRODUCTS_DIR}/$(basename \"$1\")\" ]; then\n    local source=\"${BUILT_PRODUCTS_DIR}/$(basename \"$1\")\"\n  elif [ -r \"$1\" ]; then\n    local source=\"$1\"\n  fi\n\n  local destination=\"${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}\"",
            "install_framework()\n{\n  local source=\"\"\n  if [ -e \"${BUILT_PRODUCTS_DIR}/$1\" ] || [ -L \"${BUILT_PRODUCTS_DIR}/$1\" ]; then\n    source=\"${BUILT_PRODUCTS_DIR}/$1\"\n  elif [ -e \"${BUILT_PRODUCTS_DIR}/$(basename \"$1\")\" ] || [ -L \"${BUILT_PRODUCTS_DIR}/$(basename \"$1\")\" ]; then\n    source=\"${BUILT_PRODUCTS_DIR}/$(basename \"$1\")\"\n  elif [ -e \"$1\" ] || [ -L \"$1\" ]; then\n    source=\"$1\"\n  fi\n\n  local destination=\"${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}\"\n\n  if [ -z \"${source}\" ]; then\n    echo \"error: Framework '$1' was not found.\"\n    return 1\n  fi"
        )
        source = source.gsub(
            'source="$(readlink "${source}")"',
            "local linked_source\n    linked_source=\"$(readlink \"${source}\")\"\n    if [[ \"$linked_source\" = /* ]]; then\n      source=\"$linked_source\"\n    elif [[ \"$source\" == \"${BUILT_PRODUCTS_DIR}/\"* ]]; then\n      source=\"${BUILT_PRODUCTS_DIR}/${linked_source}\"\n    else\n      source=\"$(dirname \"${source}\")/${linked_source}\"\n    fi"
        )
        unless source.include?('local archive_source="${BUILT_PRODUCTS_DIR}/../../IntermediateBuildFilesPath')
            source = source.gsub(
                "  # Use filter instead of exclude so missing patterns don't throw errors.",
                "  if [ ! -e \"${source}\" ]; then\n    local archive_source=\"${BUILT_PRODUCTS_DIR}/../../IntermediateBuildFilesPath/UninstalledProducts/${PLATFORM_NAME}/$(basename \"$1\")\"\n    if [ -e \"${archive_source}\" ]; then\n      source=\"${archive_source}\"\n    fi\n  fi\n\n  # Use filter instead of exclude so missing patterns don't throw errors."
            )
        end
        File.write(frameworks_script, source)
    end
end
