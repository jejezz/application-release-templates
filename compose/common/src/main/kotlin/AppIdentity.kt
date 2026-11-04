package art.zoomon.APP_PACKAGE

/**
 * 앱 정체성(이름·식별자·게시자·저작권)을 코드에 반영하는 유일한 곳.
 * 값의 원본은 gradle.properties의 `app.*`이고, 값의 근거는 compose/conventions identity.
 */
object AppIdentity {
    /** 표시 이름. 번역하지 않는다. */
    val displayName: String = BuildProperties.require("displayName")

    /** 릴리스 산출물과 설정 폴더에 쓰는 공백 없는 이름. */
    val fileName: String = BuildProperties.require("fileName")

    /** 번들 ID / 설치 식별자. 릴리스 후 바꾸지 않는다. */
    val id: String = BuildProperties.require("id")

    val copyrightHolder: String = BuildProperties.require("copyrightHolder")

    /** 첫 릴리스 연도. 해마다 바꾸지 않는다. */
    val firstReleaseYear: Int = BuildProperties.require("firstReleaseYear").toInt()

    val copyright: String get() = "Copyright © $firstReleaseYear $copyrightHolder"

    const val REPOSITORY_URL = "https://github.com/jejezz/APP_REPOSITORY"

    const val LICENSE_NAME = "MIT License"
}
