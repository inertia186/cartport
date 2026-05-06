PICO8_BIN ?= /Applications/PICO-8.app/Contents/MacOS/pico8
CART ?= pixels-progress

CART_DIR := pico8/$(CART)
CART_FILE := $(CART_DIR)/$(CART).p8
EXPORT_ROOT := public/carts
EXPORT_STEM := $(EXPORT_ROOT)/$(CART)
EXPORT_TMP_DIR := $(EXPORT_ROOT)/$(CART)_html
EXPORT_DIR := $(EXPORT_ROOT)/$(CART)

.PHONY: help run export-html export-png clean-export clean-exports check-pico8 check-cart print-vars

help:
	@echo "Cartport PICO-8 workflow"
	@echo
	@echo "Targets:"
	@echo "  make run CART=<slug>         Open a cart in PICO-8"
	@echo "  make export-html CART=<slug> Export HTML5 build into public/carts/<slug>/"
	@echo "  make export-png CART=<slug>  Export cartridge PNG (.p8.png) into public/carts/<slug>/"
	@echo "  make clean-export CART=<slug> Remove one exported cart directory"
	@echo "  make clean-exports           Remove all generated public/carts/* exports"
	@echo "  make print-vars CART=<slug>  Show resolved paths for the selected cart"
	@echo
	@echo "Variables:"
	@echo "  PICO8_BIN=$(PICO8_BIN)"
	@echo "  CART=$(CART)"

run: check-pico8 check-cart
	"$(PICO8_BIN)" -run "$(CART_FILE)"

export-png: check-pico8 check-cart
	mkdir -p "$(EXPORT_ROOT)"
	"$(PICO8_BIN)" "$(CART_FILE)" -export "$(EXPORT_STEM).p8.png"
	@test -f "$(EXPORT_STEM).p8.png" || (echo "PNG export was not produced. Save a label image for the cart in PICO-8 and retry." >&2; exit 1)
	@echo "Exported $(CART_FILE) -> $(EXPORT_STEM).p8.png"

export-html: check-pico8 check-cart
	mkdir -p "$(EXPORT_ROOT)"
	rm -rf "$(EXPORT_TMP_DIR)" "$(EXPORT_DIR)"
	"$(PICO8_BIN)" "$(CART_FILE)" -export "-f $(EXPORT_STEM).html"
	@test -d "$(EXPORT_TMP_DIR)" || (echo "HTML export was not produced. If PICO-8 says 'please capture a label first', save a label image for the cart in PICO-8 and retry." >&2; exit 1)
	mv "$(EXPORT_TMP_DIR)" "$(EXPORT_DIR)"
	node scripts/cache-bust-pico8-export.mjs "$(EXPORT_DIR)"
	@echo "Exported $(CART_FILE) -> $(EXPORT_DIR)/index.html"

clean-export:
	rm -rf "$(EXPORT_DIR)"

clean-exports:
	rm -rf "$(EXPORT_ROOT)"/*

check-pico8:
	@test -x "$(PICO8_BIN)" || (echo "PICO-8 binary not found at $(PICO8_BIN)" >&2; exit 1)

check-cart:
	@test -f "$(CART_FILE)" || (echo "Cart file not found: $(CART_FILE)" >&2; exit 1)

print-vars:
	@echo "PICO8_BIN=$(PICO8_BIN)"
	@echo "CART=$(CART)"
	@echo "CART_FILE=$(CART_FILE)"
	@echo "EXPORT_DIR=$(EXPORT_DIR)"
