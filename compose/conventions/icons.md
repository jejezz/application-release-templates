# 아이콘 규칙 (Compose)

Flutter용 [icons.md](../../conventions/icons.md)의 Compose 판입니다. 앱 아이콘 생성
파이프라인은 아직 옮기지 않았습니다([README](README.md)의 icons 행).

## 권고: 가능하면 Phosphor Duotone

앱 안 UI 아이콘은 **가능하면 [Phosphor Icons](https://phosphoricons.com)의 Duotone
세트**로 표현합니다. 필수가 아니라 권고이고, 이유와 세부 규칙(한 앱은 Duotone 하나로
통일, 쓰지 않는 곳, 대신 쓰는 경우)은 Flutter 규약의 해당 절과 같습니다.

- **형태**: Phosphor 공식 SVG의 `duotone` 폴더를 씁니다. Compose에는 Flutter의
  `phosphor_flutter`에 해당하는 공식 패키지를 확인하지 못했으므로, SVG를
  벡터 리소스(Android Vector Drawable 또는 `ImageVector`)로 변환해 `src/main/resources`
  (또는 앱의 리소스 위치)에 둡니다.
- **색**: 아이콘은 `LocalContentColor`(또는 `Icon`의 `tint`)를 따르게 합니다. 보조
  면은 같은 색의 옅은 투명도이므로 변환할 때 이 투명도를 지우지 않습니다.
  라이트·다크 변형을 따로 두지 않습니다.
- **공통 컴포저블 하나**로만 그립니다. 크기와 색을 이 한 곳에서 맞춥니다.
- **쓰지 않는 에셋은 저장소에 두지 않습니다.**
- **라이선스**: MIT입니다. 변환한 리소스를 번들하므로 MIT 원문을 라이선스 모음에
  넣습니다. 수집 방식은 정보 창 단계에서 정합니다([licensing.md](licensing.md)).

미정: 변환 도구(스크립트 또는 Gradle 작업)와 리소스 위치. 첫 Compose 앱에서
확인한 뒤 이 문서를 채웁니다.
