PREFIX = /usr

all: build translate

build:
	mkdir -p build
	cd build; qmake ..; make

translate:
	deepin-generate-mo po/po_config.ini

install: build translate
	mkdir -p ${DESTDIR}${PREFIX}/share/locale
	mkdir -p ${DESTDIR}/etc/xdg/autostart

	cp -r po/mo/* ${DESTDIR}${PREFIX}/share/locale/
	cd build; make INSTALL_ROOT=${DESTDIR} install
	cp dde-dock-applets-autostart.desktop ${DESTDIR}/etc/xdg/autostart/

clean:
	rm -rf build
