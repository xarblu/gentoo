# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN/-bin}"
MY_PV="${PV/-r*}"
MY_BIN="${MY_PN^}"

CHROMIUM_LANGS="
	am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk vi zh-CN zh-TW
"

inherit chromium-2 desktop linux-info optfeature pax-utils unpacker

DESCRIPTION="All-in-one voice and text chat for gamers"
HOMEPAGE="https://discordapp.com"
SRC_URI="https://dl.discordapp.net/apps/linux/${MY_PV}/${MY_PN}-${MY_PV}.tar.gz"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

# libXScrnSaver is used through dlopen (bug #825370)
RDEPEND="
	app-accessibility/at-spi2-atk:2
	app-accessibility/at-spi2-core:2
	dev-libs/atk
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libxshmfence
	x11-libs/pango
"

RESTRICT="bindist mirror strip test"

QA_PREBUILT="
	${DESTDIR}/${MY_BIN}
	${DESTDIR}/chrome-sandbox
	${DESTDIR}/libffmpeg.so
	${DESTDIR}/libvk_swiftshader.so
	${DESTDIR}/libvulkan.so
	${DESTDIR}/libEGL.so
	${DESTDIR}/libGLESv2.so
	${DESTDIR}/libVkICD_mock_icd.so
	${DESTDIR}/swiftshader/libEGL.so
	${DESTDIR}/swiftshader/libGLESv2.so
	${DESTDIR}/swiftshader/libvk_swiftshader.so
"

CONFIG_CHECK="~USER_NS"

S="${WORKDIR}/${MY_BIN}"

DESTDIR="/opt/${MY_BIN}"

pkg_pretend() {
	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	unpack ${MY_PN}-${MY_PV}.tar.gz || die
}

src_configure() {
	chromium_suid_sandbox_check_kernel_config
	default
}

src_prepare() {
	default

	rm postinst.sh

	pushd "locales/" || die
	chromium_remove_language_paks
	popd
	
	sed -i \
	-e "s:/usr/share/discord/Discord:${DESTDIR}/${MY_BIN}:" \
	${MY_PN}.desktop || die
}

src_install() {
	doicon -s 256 ${MY_PN}.png

	# Install desktop file
	domenu ${MY_PN}.desktop

	exeinto ${DESTDIR}
	doexe ${MY_BIN} chrome-sandbox libEGL.so libffmpeg.so libGLESv2.so  libvk_swiftshader.so

	insinto ${DESTDIR}
	doins chrome_100_percent.pak chrome_200_percent.pak icudtl.dat resources.pak snapshot_blob.bin v8_context_snapshot.bin
	insopts -m0755
	doins -r locales resources swiftshader

	# chrome-sandbox requires the setuid bit to be specifically set.
	# See https://github.com/electron/electron/issues/17972
	fperms 4755 ${DESTDIR}/chrome-sandbox || die

	pax-mark m ${DESTDIR}/${MY_BIN} || die "could not set proper PAX permissions"

	dosym ${DESTDIR}/${MY_BIN} /usr/bin/${MY_PN} || die

	dodir ${DESTDIR}
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
	
	optfeature "sound support" \
		media-sound/pulseaudio media-sound/apulse[sdk] media-video/pipewire
	optfeature "system tray support" dev-libs/libappindicator
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}
