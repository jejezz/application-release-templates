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
- **2026-10-29: `WindowPlacement`(크기·위치·최대화 상태를 통째로 기억)를 표준으로
  승격했습니다.** 이전 표준이던 "마지막 모니터 이름만 저장"(`LastDisplaySaver`/
  `placeWindowAtStartup`)은 daylight-terminal-flutter가 이미 쓰고 있던 더 정교한
  방식(크기·위치·최대화 상태를 통째로 기억하고 두 단계로 복원)으로 대체됩니다.
  옛 방식으로 적용돼 있던 앱(android-analyzer-flutter, bank-service-killer,
  daylight-benchmark, daylight-broom-flutter, daylight-pdf-flutter,
  kamailio-sip-client-flutter, stevedore-flutter)은 새 방식으로 다시 패치합니다.
  저장 키가 다르므로(`window_display` → `window_placement`) 옛 기록은 그냥 무시되고
  새로 시작합니다(창 위치는 편의 기능이라 데이터 손실이 아닙니다).
- **도킹 창 전용 앱은 이 규칙을 따르지 않습니다.** branch-dock-flutter/flutty-dock-flutter/
  dove-zip-flutter/notes2hub-flutter는 창 자체가 가장자리에 붙는 도킹 창이라, 전체
  좌표(크기+위치)를 따로 기억하고 Windows에서는 네이티브 러너나 물리 픽셀 계산으로 첫
  위치를 정하는 자체 해법이 이미 있습니다. 그대로 둡니다.
- **일반 창과 도킹 모드를 오가는 앱**(daylight-commander, snapdock)은 일반 창의 위치만
  이 규칙으로 기억합니다. `WindowPlacement(isDocked: ...)`에 도킹 여부를 넘기면 도킹
  중에는 저장하지 않아, 다음 실행 때 도킹 전 크기로 돌아옵니다. 도킹으로 시작하는 경우
  `placeInitially()`는 부르지 않고 `attach()`만 합니다.
- **2026-10-30: §5(창을 첫 프레임 뒤에 보이기)를 추가했습니다.** 그 전에 이 규칙을
  적용한 앱은 `windows/runner/flutter_window.cpp`의 자동 `this->Show()`를 안
  지웠을 가능성이 커 같은 깜빡임·크기 점프가 있을 수 있습니다. 확인·패치가 필요합니다.

## 규칙

### 1. 원인: `setBounds`는 "창이 지금 있는 모니터의 배율"을 곱한다

`window_manager.setBounds(Rect)`는 넘긴 좌표에 **그 순간 창이 속한 모니터의 배율**을
곱해 물리 픽셀로 바꿉니다. 창은 주 모니터에서 만들어지므로 배율이 다른 보조
모니터 좌표를 그대로 넘기면 배율 비율만큼 어긋납니다. 예: 주 175%, 보조 100%에서
보조 모니터 가운데(3565)를 넘기면 3565×1.75 = 6238이 되어 보조 모니터 오른쪽
끝(5440) 밖에 놓입니다. `getBounds`도 같은 배율로 되돌려 주기 때문에 읽어 본 값은
항상 요청한 값과 같습니다.

### 2. `WindowPlacement`가 크기·위치·최대화 상태를 통째로 기억한다

모든 계산은 **물리 픽셀**로 한다 — `DisplayArea`(모니터 작업 영역, 물리 픽셀)와
`SavedPlacement`(마지막 창 경계 + 저장 시점 배율 + 최대화 여부)가 그 단위다.
`PlacementMath.restore`는 저장된 사각형이 가장 많이 걸치는 모니터를 찾아, 그
모니터의 배율이 저장 시점과 다르면 크기를 비례해서 환산하고 작업 영역 안으로
당겨 넣는다. 걸치는 모니터가 없으면(모니터를 뗀 경우 등) null — 그러면 주 모니터
가운데에 연다.

### 3. 시작 위치는 필요할 때만 두 단계로 놓는다 (`WindowPlacement.placeInitially`)

목표 모니터의 배율이 창이 **지금** 있는 모니터(보통 주 모니터)와 다르면 한 번에
정확히 놓을 수 없다. 그럴 때만 1단계로 목표 모니터 안쪽(여유 40px)으로
`setPosition`한 뒤 `getDevicePixelRatio()`가 목표 배율로 바뀔 때까지 기다리고(최대
12×50ms), 2단계로 그 배율 기준 좌표로 `setBounds`해 정확한 위치·크기를 맞춘다.
배율이 이미 같으면(단일 모니터 등, 흔한 경우) 1단계를 건너뛰고 바로 `setBounds`한다
— 모니터를 안 옮기므로 불필요한 지연과 리페인트가 없다.

### 4. 위치·크기·최대화 상태를 묶어서 저장한다

`attach()`로 등록한 리스너가 창을 옮기거나 크기를 바꾼 뒤 500ms 모아서
`saveNow()`를 부른다. 최소화·전체 화면 중에는 저장하지 않는다. 최대화 중이면
최대화 **직전** 크기·위치는 그대로 두고 "최대화했다"는 사실만 새로 적어서,
복원했다가 최대화를 풀면 원래 크기로 돌아온다. 저장 키는 `window_placement`
하나(JSON: `x`, `y`, `w`, `h`, `scale`, `max`)다 — 좌표만 저장하던 옛 키
(`window_display` 등)와 겹치지 않는다.

### 5. 창은 첫 프레임이 그려진 뒤에 보여야 깜빡이지 않는다

**2026-10-30: daylight-commander-flutter에서 발견 — Flutter의 Windows 기본 템플릿은
`windows/runner/flutter_window.cpp`에 "첫 프레임이 그려지면 네이티브 코드가 바로
창을 보여주는" 코드(`SetNextFrameCallback([&]{ this->Show(); })`)를 기본으로
넣는다. 이게 `WindowPlacement.placeInitially()`보다 먼저 끝나 버리면, 창이
아직 최종 모니터·배율로 옮기기 전(기본 `origin (10, 10)`, 주 모니터 배율) 크기로
먼저 보였다가 자리 잡으며 커졌다 줄었다 하는 게 비친다 — 듀얼 모니터뿐 아니라
단일 모니터에서도 테마 안 입혀진 빈 화면이 잠깐 보였다 바뀌는 깜빡임으로
나타난다.** 두 가지를 같이 해야 고쳐진다:

1. **`windows/runner/flutter_window.cpp`에서 그 자동 `this->Show()`를 지운다**
   (`flutter_controller_->ForceRedraw();` 호출은 그대로 둔다). `window_manager`
   패키지 자체 문서(`SetNextFrameCallback` 섹션)에도 같은 안내가 있다 — 창 표시를
   `window_manager` 쪽에서 전적으로 맡기기 위해서다.
2. **Dart 쪽 `windowManager.show()`를 Flutter의 첫 프레임이 그려진 뒤로 미룬다.**
   `waitUntilReadyToShow`의 콜백에서 배치만 끝내고(`show()`는 부르지 않는다),
   `runApp()` 뒤에 등록한 `addPostFrameCallback`이 그 배치가 끝난 것까지 확인한 뒤
   `show()`를 부른다. 배치가 끝난 직후에도 그 크기로 다시 그릴 프레임이 아직 안
   나왔을 수 있어, 프레임을 한 번 더 기다린다.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();

  Future<void> Function()? showWindow;
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    showWindow = await _prepareWindow();
  }

  final settings = await AppSettings.load();
  final updates = await UpdateService.create();
  runApp(UpdateScope(service: updates, child: App(settings: settings, updates: updates)));

  if (showWindow != null) {
    final show = showWindow;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(show()));
  }
}

Future<void> _nextFrame() {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
  WidgetsBinding.instance.scheduleFrame();
  return completer.future;
}

Future<Future<void> Function()> _prepareWindow() async {
  const size = Size(1200, 720);
  WindowPlacement? placement;
  if (WindowPlacement.enabled) {
    placement = WindowPlacement(await SharedPreferences.getInstance(), defaultSize: size);
  }
  final options = WindowOptions(
    size: size,
    minimumSize: const Size(960, 600),
    center: placement == null,
    title: '<표시 이름>',
  );
  final placed = Completer<void>();
  windowManager.waitUntilReadyToShow(options, () async {
    await placement?.placeInitially();
    placed.complete();
  });
  return () async {
    await placed.future;
    await _nextFrame();
    await windowManager.show();
    await windowManager.focus();
    placement?.attach();
  };
}
```

전체는 [`../common/lib/main.dart`](../common/lib/main.dart)에 있다. `placement?.attach()`는
`show()` 뒤에 불러도 된다 — 리스너만 등록할 뿐 아직 저장은 하지 않는다. 앱을 끝낼
때 `placement?.detach()`를 부를 필요는 없다(프로세스가 끝나면 같이 끝난다); 다만
창을 직접 닫지 않고 숨겨 재사용하는 상주 앱이라면 다시 보일 때 쓰고 있는 인스턴스를
그대로 쓴다.

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
3. `main()`을 §5 예시(또는 `common/lib/main.dart`)처럼 구성합니다: `WindowPlacement`를
   만들어 `placeInitially`를 연결하고(`center: true`를 쓰던 자리는
   `center: placement == null`로 바꿉니다), `windowManager.show()`는 첫 프레임이
   그려진 뒤로 미룹니다.
4. **`windows/runner/flutter_window.cpp`에서 `SetNextFrameCallback`의
   `this->Show();`를 지웁니다** — 안 지우면 3번이 무의미해집니다(§5).
5. `common/test/window_placement_test.dart`를 `test/`에 복사하고 `<package>`를
   앱 이름으로 바꿉니다.
6. 듀얼 모니터 환경(배율이 다른 조합)에서 보조 모니터로 옮기고 크기를 바꾼 뒤
   종료하고 다시 실행해 그 크기·위치로 돌아오는지, 최대화한 채 끝내면 최대화로
   열리는지, 시작할 때 창 안 내용이 커졌다 줄어들거나 빈 화면이 깜빡이지 않는지
   확인합니다.
