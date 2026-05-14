# SPDX-License-Identifier: MIT
# Copyright (c) 2026 netlinux-ai and contributors

PREFIX ?= /usr/local
DESKTOP = battery-tray.desktop
BIN = $(PREFIX)/bin/battery-tray

install:
	install -Dm755 battery-tray $(DESTDIR)$(BIN)
	install -Dm644 $(DESKTOP) $(DESTDIR)$(PREFIX)/share/applications/$(DESKTOP)
	install -Dm644 $(DESKTOP) $(DESTDIR)/etc/xdg/autostart/$(DESKTOP)
	@if [ -z "$(DESTDIR)" ]; then \
		update-desktop-database $(PREFIX)/share/applications 2>/dev/null || true; \
		user=$${SUDO_USER:-$$(id -un)}; \
		pkill -u "$$user" -fx "python3 $(BIN)" 2>/dev/null || true; \
		sleep 1; \
		if [ "$$user" = "$$(id -un)" ]; then \
			setsid --fork $(BIN) </dev/null >/dev/null 2>&1; \
		else \
			runuser -u "$$user" -- env DISPLAY=$${DISPLAY:-:0} setsid --fork $(BIN) </dev/null >/dev/null 2>&1; \
		fi; \
		echo "battery-tray (re)started as $$user"; \
	fi

uninstall:
	rm -f $(DESTDIR)$(BIN)
	rm -f $(DESTDIR)$(PREFIX)/share/applications/$(DESKTOP)
	rm -f $(DESTDIR)/etc/xdg/autostart/$(DESKTOP)
	@if [ -z "$(DESTDIR)" ]; then \
		user=$${SUDO_USER:-$$(id -un)}; \
		pkill -u "$$user" -fx "python3 $(BIN)" 2>/dev/null || true; \
		update-desktop-database $(PREFIX)/share/applications 2>/dev/null || true; \
	fi

.PHONY: install uninstall
