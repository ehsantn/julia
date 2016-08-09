## CURL ##

$(BUILDDIR)/curl-$(CURL_VER)/build-configured: | $(build_prefix)/manifest/libssh2
$(BUILDDIR)/curl-$(CURL_VER)/build-configured: | $(build_prefix)/manifest/mbedtls

ifneq ($(OS),WINNT)
CURL_LDFLAGS := $(RPATH_ESCAPED_ORIGIN)
endif

$(SRCDIR)/srccache/curl-$(CURL_VER).tar.bz2: | $(SRCDIR)/srccache
	$(JLDOWNLOAD) $@ https://curl.haxx.se/download/curl-$(CURL_VER).tar.bz2

$(SRCDIR)/srccache/curl-$(CURL_VER)/source-extracted: $(SRCDIR)/srccache/curl-$(CURL_VER).tar.bz2
	$(JLCHECKSUM) $<
	cd $(dir $<) && $(TAR) jxf $(notdir $<)
	touch -c $(SRCDIR)/srccache/curl-$(CURL_VER)/configure # old target
	echo 1 > $@

$(BUILDDIR)/curl-$(CURL_VER)/build-configured: $(SRCDIR)/srccache/curl-$(CURL_VER)/source-extracted
	mkdir -p $(dir $@)
	cd $(dir $@) && \
	$(dir $<)/configure $(CONFIGURE_COMMON) --includedir=$(build_includedir) --with-mbedtls=$(build_shlibdir)/.. CFLAGS="$(CFLAGS) $(CURL_CFLAGS)" LDFLAGS="$(LDFLAGS) $(CURL_LDFLAGS)"
	echo 1 > $@

$(BUILDDIR)/curl-$(CURL_VER)/build-compiled: $(BUILDDIR)/curl-$(CURL_VER)/build-configured
	$(MAKE) -C $(dir $<) $(LIBTOOL_CCLD)
	echo 1 > $@

$(BUILDDIR)/curl-$(CURL_VER)/build-checked: $(BUILDDIR)/curl-$(CURL_VER)/build-compiled
ifeq ($(OS),$(BUILD_OS))
	$(MAKE) -C $(dir $@) check
endif
	echo 1 > $@

$(eval $(call staged-install, \
	curl,curl-$$(CURL_VER), \
	MAKE_INSTALL,$$(LIBTOOL_CCLD),, \
	$$(INSTALL_NAME_CMD)libcurl.$$(SHLIB_EXT) $$(build_shlibdir)/libcurl.$$(SHLIB_EXT)))

clean-curl:
	-rm -rf $(build_prefix)/manifest/curl \
		$(BUILDDIR)/curl-$(CURL_VER)/build-configured $(BUILDDIR)/curl-$(CURL_VER)/build-compiled
	-$(MAKE) -C $(BUILDDIR)/curl-$(CURL_VER) clean

distclean-curl:
	-rm -rf $(SRCDIR)/srccache/curl-$(CURL_VER).tar.bz2 $(SRCDIR)/srccache/curl-$(CURL_VER) $(BUILDDIR)/curl-$(CURL_VER)

get-curl: $(SRCDIR)/srccache/curl-$(CURL_VER).tar.bz2
extract-curl: $(SRCDIR)/srccache/curl-$(CURL_VER)/source-extracted
configure-curl: $(BUILDDIR)/curl-$(CURL_VER)/build-configured
compile-curl: $(BUILDDIR)/curl-$(CURL_VER)/build-compiled
fastcheck-curl: #none
check-curl: $(BUILDDIR)/curl-$(CURL_VER)/build-checked