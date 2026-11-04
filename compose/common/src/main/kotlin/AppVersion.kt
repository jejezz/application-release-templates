package art.zoomon.APP_PACKAGE

/** 앱 버전. Flutter 앱의 `package_info_plus` 자리. 원본은 gradle.properties의 app.version / app.build. */
object AppVersion {
    /** 예: `1.0.0-rc.1`. 리소스를 못 읽으면 로컬 빌드임이 보이도록 `0.0.0`. */
    val version: String = BuildProperties["version"] ?: "0.0.0"

    val build: Int = BuildProperties["build"]?.toIntOrNull() ?: 0

    /** 정보 창 표시용: `1.0.0-rc.1 (1)` */
    val display: String get() = "$version ($build)"
}
