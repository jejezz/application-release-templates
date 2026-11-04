package art.zoomon.APP_PACKAGE

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppIdentityTest {
    @Test
    fun `표시 이름과 파일 이름`() {
        assertTrue(AppIdentity.displayName.isNotBlank())
        assertTrue(Regex("""[A-Z][A-Za-z0-9]*""").matches(AppIdentity.fileName), "파일 이름은 공백 없는 PascalCase")
        assertEquals(AppIdentity.displayName.replace(" ", ""), AppIdentity.fileName)
    }

    @Test
    fun `식별자는 art_zoomon 접두어의 소문자 역도메인`() {
        assertTrue(Regex("""art\.zoomon\.[a-z0-9]+(\.[a-z0-9]+)*""").matches(AppIdentity.id), AppIdentity.id)
    }

    @Test
    fun `저작권 문자열은 연도와 저작권자 한 가지 형식`() {
        assertTrue(Regex("""Copyright © \d{4} Jongyun Ahn""").matches(AppIdentity.copyright), AppIdentity.copyright)
    }
}
