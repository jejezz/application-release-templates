# Application Release Templates

여러 Flutter 앱에 그대로 옮겨 쓸 수 있게 일반화한 GitHub Actions 릴리스
워크플로 템플릿 모음입니다. 배포 방식이 근본적으로 다른 두 그룹으로
나뉩니다.

| 템플릿 | 대상 | 배포 방식 |
|---|---|---|
| [`mobile/`](mobile/) | iOS, Android | Fastlane으로 TestFlight / Play 내부 테스트 트랙에 업로드 |
| [`desktop/`](desktop/) | macOS, Windows, Linux | 태그 푸시 → GitHub Release에 빌드 산출물 직접 첨부 (macOS는 Developer ID 서명 + 공증 포함) |

각 폴더의 README가 실제 적용 방법(복사할 파일, 고쳐야 할 자리, 등록할
시크릿)을 다룹니다. 두 템플릿 모두 최초 도입 시 실제 앱 저장소에서 끝까지
검증한 뒤 이곳으로 일반화했습니다 — `mobile/`은
[saturn-mobile-client-flutter](https://github.com/ptype-co-kr/saturn-mobile-client-flutter),
`desktop/`은 [portside-flutter](https://github.com/jejezz/portside-flutter)가
그 실제 예시입니다.
