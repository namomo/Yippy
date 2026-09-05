# Yippy

Yippy는 macOS용 오픈소스 클립보드 매니저입니다. 메뉴 막대에서 빠르게 열 수 있는 클립보드 히스토리 패널을 제공하고, 복사했던 항목을 검색하거나 다시 붙여넣을 수 있습니다.

![screenshot](images/screenshot.jpg)

## 주요 기능

- 메뉴 막대 앱으로 동작하는 클립보드 히스토리 패널
- 클립보드 항목 검색
- 키보드 단축키로 패널 열기, 항목 이동, 선택 항목 붙여넣기
- 텍스트, 이미지, 파일 등 여러 pasteboard 타입 저장
- 히스토리 항목 삭제 및 전체 비우기
- 로그인 시 자동 실행 옵션
- 패널 위치 설정

## 설치

공개 릴리스는 기존 프로젝트 사이트에서 받을 수 있습니다.

- https://yippy.mattdavo.com
- https://yippy.mattdavo.com/releases

Homebrew Cask로 설치할 수도 있습니다.

```sh
brew install --cask yippy
```

설치 도움말:

- https://yippy.mattdavo.com/installation

## 개발 환경

이 프로젝트는 Xcode 프로젝트와 CocoaPods 의존성을 함께 사용합니다. 따라서 Xcode에서 열거나 빌드할 때는 반드시 루트의 `Yippy.xcworkspace`를 사용해야 합니다.

```text
Yippy.xcworkspace
```

`Yippy.xcodeproj`만 열면 CocoaPods로 연결된 모듈을 찾지 못해 다음과 같은 오류가 발생할 수 있습니다.

```text
Unable to resolve module dependency: 'RxSwift'
Unable to resolve module dependency: 'RxRelay'
Unable to resolve module dependency: 'RxCocoa'
Unable to resolve module dependency: 'LoginServiceKit'
```

### 의존성

주요 의존성은 `Podfile`과 Swift Package 설정에 정의되어 있습니다.

- CocoaPods: `Default`, `LoginServiceKit`, `RxSwift`, `RxCocoa`
- Swift Package Manager: `HotKey`, `Fuse`

Pods가 없거나 의존성이 맞지 않으면 루트에서 다음 명령을 실행합니다.

```sh
pod install
```

그 다음 Xcode에서 `Yippy.xcworkspace`를 다시 엽니다.

## Xcode에서 빌드하기

1. Xcode에서 `/Users/dongho/work/github/Yippy/Yippy.xcworkspace`를 엽니다.
2. Scheme을 `Yippy`로 선택합니다.
3. 실행 대상은 `My Mac` 또는 `Any Mac`을 선택합니다.
4. 메뉴에서 `Product > Build`를 실행하거나 `Command-B`를 누릅니다.

Debug 빌드 산출물은 Xcode의 DerivedData 아래에 생성됩니다. Xcode Organizer를 통한 배포용 결과물이 필요하면 아래 Archive 절차를 사용합니다.

## 배포용 앱 만들기

Xcode UI에서 최종 배포용 `Yippy.app`을 만들려면 Archive와 Distribute App 흐름을 사용합니다.

1. Xcode에서 `Yippy.xcworkspace`를 엽니다.
2. Scheme을 `Yippy`로 선택합니다.
3. 메뉴에서 `Product > Archive`를 실행합니다.
4. Archive가 완료되면 Xcode Organizer의 Archives 목록에서 방금 생성된 archive를 선택합니다.
5. `Distribute App`을 누릅니다.
6. `Select a method for distribution` 단계에서 `Direct Distribution`을 선택합니다.
7. 서명 및 배포 옵션을 확인하며 진행합니다.
8. 처리가 완료되어 status가 `Ready to distribute`가 되면 해당 archive 위에 마우스를 올리고 `Export`를 선택합니다.
9. 원하는 위치를 선택하면 배포용 `Yippy.app`이 생성됩니다.

직접 배포할 앱을 만들 때는 `Direct Distribution`이 적합합니다. 다른 사용자에게 배포하는 경우에는 서명과 notarization 상태를 함께 확인해야 macOS 보안 경고를 줄일 수 있습니다.

## 터미널에서 빌드하기

터미널에서도 workspace 기준으로 빌드해야 합니다.

```sh
cd /Users/dongho/work/github/Yippy

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -workspace Yippy.xcworkspace \
  -scheme Yippy \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /private/tmp/Yippy-DerivedData \
  build
```

Release 빌드:

```sh
cd /Users/dongho/work/github/Yippy

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -workspace Yippy.xcworkspace \
  -scheme Yippy \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath /private/tmp/Yippy-Release-DerivedData \
  build
```

Release 결과물 위치:

```text
/private/tmp/Yippy-Release-DerivedData/Build/Products/Release/Yippy.app
```

Archive를 터미널에서 만들 수도 있습니다.

```sh
cd /Users/dongho/work/github/Yippy

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild archive \
  -workspace Yippy.xcworkspace \
  -scheme Yippy \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath /private/tmp/Yippy.xcarchive
```

Archive 안의 앱 위치:

```text
/private/tmp/Yippy.xcarchive/Products/Applications/Yippy.app
```

## Scheme

프로젝트에는 세 가지 주요 scheme이 있습니다.

- `Yippy`: 일반 실행 및 production archive용
- `Yippy Beta`: 개발 및 beta release archive용
- `Yippy XCTest`: unit test와 UI test 실행용

## 인스톨러 만들기

`create-installer.sh`는 `.app`을 `.dmg` 인스톨러로 패키징할 때 사용합니다.

먼저 `create-dmg`를 설치합니다.

```sh
brew install create-dmg
```

그 다음 `create-installer.sh`와 같은 디렉터리에 `Yippy.app`을 둔 뒤 실행합니다.

```sh
./create-installer.sh Yippy
```

완료되면 같은 디렉터리에 `Yippy.dmg`가 생성됩니다.

## 커밋 시 주의할 파일

다음 파일들은 개인 환경 또는 빌드 산출물에 가깝기 때문에 일반 기능 커밋에 포함하지 않는 것이 좋습니다.

- `.DS_Store`
- `*.xcuserstate`
- `xcuserdata/`
- `Yippy.app/` 아래 빌드 결과물 변경

기능 변경 커밋에는 보통 `Yippy/Sources/`, `Yippy/Resources/`, `Yippy.xcodeproj/`, `Podfile`, `doc/` 등 실제 소스와 설정 변경만 포함합니다.

## 문서

기능별 작업 문서는 `doc/features/` 아래에 둡니다. 구현 전 아이디어, 확정된 동작, 열린 결정, 검증 체크리스트를 함께 기록합니다.

## 참고 링크

- 프로젝트 사이트: https://yippy.mattdavo.com
- 블로그: https://yippy.mattdavo.com/blog
- 릴리스: https://yippy.mattdavo.com/releases

## TODO

- [ ] 더 많은 pasteboard item 타입 지원
- [ ] 키보드 단축키 설정 개선
  - [x] Toggle hotkey 커스터마이즈
- [ ] 자동 업데이트 지원 검토
- [ ] 오류 보고 흐름 추가
- [x] 접근 권한이 없을 때 앱 기능 사용 제한
- [x] Attributed text 표시 토글
- [x] 로그인 시 실행
- [x] 히스토리 저장 구조 개선
- [ ] 즐겨찾기 또는 고정 항목 개선
- [x] 검색
- [ ] 검색 랭킹 및 fuzzy search 개선
- [x] 최대 히스토리 길이 설정
- [ ] 셀 높이 캐시 개선
  - [x] 셀 높이 캐시 비우기
  - [ ] 셀 높이를 디스크에 저장
