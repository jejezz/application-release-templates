package art.zoomon.APP_PACKAGE

import java.util.Properties

/**
 * 빌드 때 gradle.properties의 `app.*` 값이 채워진 app.properties 리소스.
 * 버전·정체성은 코드에 하드코딩하지 않고 여기서만 읽는다.
 */
internal object BuildProperties {
    private val props = Properties().apply {
        BuildProperties::class.java.getResourceAsStream("/app.properties")?.use(::load)
    }

    operator fun get(key: String): String? = props.getProperty(key)

    fun require(key: String): String =
        get(key) ?: error("app.properties에 '$key'가 없음 — 리소스가 빌드되지 않았다")
}
