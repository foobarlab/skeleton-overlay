# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils multilib pax-utils user

DESCRIPTION="Distributed, fault-tolerant and schema-free document-oriented database"
HOMEPAGE="https://couchdb.apache.org/"
SRC_URI="mirror://apache/couchdb/source/${PV}/apache-${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="libressl selinux test"

RDEPEND=">=dev-libs/icu-4.3.1:=
		<dev-lang/erlang-20.0[ssl]
		!libressl? ( >=dev-libs/openssl-0.9.8j:0 )
		libressl? ( dev-libs/libressl )
		>=net-misc/curl-7.18.2
		<dev-lang/spidermonkey-1.8.7
		selinux? ( sec-policy/selinux-couchdb )"

DEPEND="${RDEPEND}
		sys-devel/autoconf-archive"
RESTRICT=test

S="${WORKDIR}/apache-${P}"

pkg_setup() {
	enewgroup couchdb
	enewuser couchdb -1 -1 /var/lib/couchdb couchdb
}

#src_prepare() {
	#sed -i ./src/couchdb/priv/Makefile.* -e 's|-Werror||g'
	#epatch "${FILESDIR}/${PV}-erlang-18.patch"
	#epatch "${FILESDIR}/${PV}-erlang-19.patch"
#	eautoreconf
#}

src_configure() {
	econf \
		--with-erlang="${EPREFIX}"/usr/$(get_libdir)/erlang/usr/include \
		--localstatedir="${EPREFIX}"/var \
		--with-js-lib="${EPREFIX}"/usr/$(get_libdir)
	# bug 296609, upstream bug #COUCHDB-621
	#sed -e "s#localdocdir = /usr/share/doc/couchdb#localdocdir = "${EPREFIX}"/usr/share/doc/${PF}#" -i Makefile || die "sed failed"
}

src_compile() {
	emake release
	# bug 442616
	#pax-mark mr src/couchdb/priv/couchjs
}

src_test() {
	emake distcheck
}

src_install() {
	#emake DESTDIR="${D}" install
	mkdir -p ${D}/opt
	cp -r ${S}/rel/couchdb ${D}/opt/

	keepdir /var/l{ib,og}/couchdb

	fowners couchdb:couchdb \
		/var/lib/couchdb \
		/var/log/couchdb

	fowners -R couchdb:couchdb /opt/couchdb

	for f in "${ED}"/opt/couchdb/etc/*.ini ; do
		fowners couchdb:couchdb "${f#${ED}}"
		fperms 644 "${f#${ED}}"
	done
	#fperms 664 /etc/couchdb/default.ini

	#fperms 0644 /opt/couchdb/etc/*

	newinitd "${FILESDIR}/couchdb.init-4" couchdb
	newconfd "${FILESDIR}/couchdb.conf-2" couchdb

	sed -i -e "s:LIBDIR:$(get_libdir):" "${ED}/etc/conf.d/couchdb"
}
