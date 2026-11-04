package art.zoomon.APP_PACKAGE

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class AppVersionTest {
    @Test
    fun `빌드가 채운 버전은 SemVer 형식이고 폴백이 아니다`() {
        assertNotEquals("0.0.0", AppVersion.version, "app.properties가 필터링되지 않음")
        assertTrue(
            Regex("""\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?""").matches(AppVersion.version),
            "버전 형식: ${AppVersion.version}",
        )
    }

    @Test
    fun `MAJOR는 1 이상 - jpackage가 macOS에서 0 시작을 거부한다`() {
        val major = AppVersion.version.substringBefore('.').toInt()
        assertTrue(major >= 1, "버전: ${AppVersion.version}")
    }

    @Test
    fun `build number는 1 이상`() {
        assertTrue(AppVersion.build >= 1, "build: ${AppVersion.build}")
    }

    @Test
    fun `표시 문자열은 버전과 build number`() {
        assertEquals("${AppVersion.version} (${AppVersion.build})", AppVersion.display)
    }
}
