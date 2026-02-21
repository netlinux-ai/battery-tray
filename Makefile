PREFIX ?= /usr/local

install:
	install -Dm755 battery-tray $(DESTDIR)$(PREFIX)/bin/battery-tray
	install -Dm644 battery-tray.desktop $(DESTDIR)/etc/xdg/autostart/battery-tray.desktop
