# 창 시작 위치 (데스크톱)

데스크톱 앱이 창을 처음 띄우는 위치를 정하는 규칙입니다. 모니터가 둘 이상이고
**모니터마다 배율이 다른 Windows**에서 `center: true`나 저장 좌표 복원이 창을
화면 밖에 놓는 문제가 실제로 여러 앱에서 반복돼서 만들었습니다.

복사용 코드는 [`../common/lib/window/window_placement.dart`](../common/lib/window/window_placement.dart)와
[`../common/test/window_placement_test.dart`](../common/test/window_placement_test.dart)입니다.

## 현재 상태

- `WindowOptions(center: true)`와 `windowManager.center()`는 마우스 커서가 있는
  모니터를 `screen_retriever` 좌표로 찾아 가운데를 계산합니다. 배율이 다른 보조
  모니터에서는 이 좌표가 `window_manager`가 해석하는 좌표와 어긋납니다.
- 마지막 위치를 저장해 `setBounds`로 복원해도, 같은 이유로 보조 모니터에서는 창이
  모니터 밖에 놓입니다. `getBounds`로 읽은 값은 늘 맞게 보여서 로그만으로는
  잡히지 않습니다.
- 앱마다 각자 고친 방식이 다릅니다(물리 픽셀 계산, 네이티브 채널, C++ 러너, 재시도
  루프). 새 앱은 아래 규칙 하나를 씁니다.

## 규칙

### 1. 원인: `setBounds`는 "창이 지금 있는 모니터의 배율"을 곱한다

`window_manager.setBounds(Rect)`는 넘긴 좌표에 **그 순간 창이 속한 모니터의 배율**을
곱해 물리 픽셀로 바꿉니다. 창은 주 모니터에서 만들어지므로 배율이 다른 보조
모니터 좌표를 그대로 넘기면 배율 비율만큼 어긋납니다. 예: 주 175%, 보조 100%에서
보조 모니터 가운데(3565)를 넘기면 3565×1.75 = 6238이 되어 보조 모니터 오른쪽
끝(5440) 밖에 놓입니다. `getBounds`도 같은 배율로 되돌려 주기 때문에 읽어 본 값은
항상 요청한 값과 같습니다.

### 2. 시작 위치는 `placeWindowAtStartup`으로 정한다

`WindowOptions`에는 `center: false`를 쓰고, `waitUntilReadyToShow` 안에서 `show()`
**전에** 부릅니다.

```dart
const size = Size(1200, 720);
await windowManager.waitUntilReadyToShow(
  const WindowOptions(size: size, minimumSize: Size(960, 600), center: false, title: '<표시 이름>'),
  () async {
    await placeWindowAtStartup(size);
    await windowManager.show();
    await windowManager.focus();
    LastDisplaySaver().start();   // 선택
  },
);
```

- Windows이고 모니터가 둘 이상: **마지막에 쓰던 모니터** 가운데(기록이 없거나 그 모니터가
  없으면 주 모니터).
- 그 밖(모니터 하나, macOS, Linux): `windowManager.center()`.

### 3. 다른 모니터로 옮길 때는 두 번에 나눠 `setBounds`한다

`centerWindowOnDisplay`가 합니다. 1차는 `대상 배율 / 주 모니터 배율`을 곱한 좌표로
대상 모니터 안에 먼저 올리고, 창이 그 모니터의 배율로 넘어간 뒤(`getBounds` 왕복
한 번) 2차로 대상 배율 기준 좌표를 줍니다. 한 번에 정확히 놓으려고 하지 않습니다.

### 4. 마지막 모니터 기억은 이름만 저장한다

`LastDisplaySaver`가 창을 옮기거나 크기를 바꾼 뒤 모니터 이름(`window_display`
키)만 저장합니다. 좌표를 저장하지 않으므로 배율이 달라도 어긋날 일이 없습니다.
창 크기·위치를 따로 기억하는 앱은 기존 키를 그대로 두고 이 키만 더합니다.
모니터 이름은 재연결로 바뀔 수 있으며, 그때는 주 모니터에서 엽니다.

### 5. 창이 어느 모니터에 있는지는 배율을 환산해서 판정한다

`displayNameForBounds`가 `window_manager` 좌표(지금 모니터 배율 적용값)의 중심을 각
모니터의 배율로 환산해 그 모니터 영역에 드는지 봅니다.

## 알아둘 점

- 직접 겪은 사례에서는 PowerToys **FancyZones**가 새 창을 "마지막 구역"으로 옮겨 앱이
  계산한 위치를 덮어썼습니다. 위치가 이상하면 이런 창 관리 유틸리티부터 끄고
  확인합니다.
- `getBounds`가 요청 좌표와 같다고 해서 화면에서도 맞는 것은 아닙니다. 보조
  모니터 확인은 실제 화면으로 합니다.
- 도킹처럼 특정 모니터 가장자리에 붙이는 동작은 이 규칙이 다루지 않습니다.
- macOS/Linux는 이 문제가 확인되지 않아 `center()`를 그대로 씁니다.

## 적용 방법

1. `common/lib/window/window_placement.dart`를 `lib/window/`에 복사합니다.
2. `flutter pub add window_manager screen_retriever shared_preferences`
3. `main()`의 `WindowOptions`에서 `center: true`를 `center: false`로 바꾸고,
   위 예시처럼 `placeWindowAtStartup`/`LastDisplaySaver`를 연결합니다.
4. `common/test/window_placement_test.dart`를 `test/`에 복사하고 `<package>`를
   앱 이름으로 바꿉니다.
5. 듀얼 모니터 환경(배율이 다른 조합)에서 보조 모니터로 옮겨 종료한 뒤 다시 실행해
   그 모니터 가운데에 뜨는지 확인합니다.
