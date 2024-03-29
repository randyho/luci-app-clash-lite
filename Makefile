include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-clash-lite
PKG_VERSION:=0.1.0
PKG_MAINTAINER:=Randy

include $(TOPDIR)/feeds/luci/luci.mk

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

define Package/$(PKG_NAME)
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for Clash
	PKGARCH:=all
	DEPENDS:=+dnsmasq-full +coreutils +coreutils-nohup +bash +curl +ca-bundle +ipset +ip-full \
	+iptables +iptables-mod-tproxy +libcap +libcap-bin +libuci-lua +lyaml +kmod-tun +unzip
	MAINTAINER:=Randy
endef

define Package/$(PKG_NAME)/description
    A LuCI support for clash
endef

define Package/$(PKG_NAME)/conffiles
/etc/clash/profiles/
/etc/config/clash
endef

define Build/Prepare
	$(call Build/Prepare/Default)

	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(foreach po,$(wildcard ${CURDIR}/po/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
	chmod -R 0755 $(PKG_BUILD_DIR)/root/usr/share/clash/
	mkdir -p $(PKG_BUILD_DIR)/root/etc/clash/core
	mkdir -p $(PKG_BUILD_DIR)/root/etc/clash/config
	mkdir -p $(PKG_BUILD_DIR)/root/etc/clash/rule_provider
	mkdir -p $(PKG_BUILD_DIR)/root/etc/clash/proxy_provider
	exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(CURDIR)/root/etc/init.d/clash $(1)/etc/init.d/clash

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF) $(CURDIR)/root/etc/config/clash $(1)/etc/config/clash

	$(INSTALL_DIR) $(1)/etc/clash/
	$(INSTALL_DATA) $(DL_DIR)/$(COUNTRY_MMDB_FILE) $(1)/etc/clash/Country.mmdb

	$(INSTALL_DIR) $(1)/usr/share/clash/
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/clash/build_conf.lua $(1)/usr/share/clash/build_conf.lua
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/clash/create_rules.sh $(1)/usr/share/clash/create_rules.sh
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/clash/clear_rules.sh $(1)/usr/share/clash/clear_rules.sh
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/clash/update_profile.sh $(1)/usr/share/clash/update_profile.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
