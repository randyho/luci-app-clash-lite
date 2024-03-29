include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-clash-lite
PKG_VERSION:=0.1.0
PKG_MAINTAINER:=Randy

include $(TOPDIR)/feeds/luci/luci.mk

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
	config PACKAGE_kmod-inet-diag
	default y if PACKAGE_$(PKG_NAME)

	config PACKAGE_luci-compat
	default y if PACKAGE_$(PKG_NAME)

	config PACKAGE_kmod-nft-tproxy
	default y if PACKAGE_firewall4

	config PACKAGE_kmod-ipt-nat
	default y if ! PACKAGE_firewall4

	config PACKAGE_iptables-mod-tproxy
	default y if ! PACKAGE_firewall4

	config PACKAGE_iptables-mod-extra
	default y if ! PACKAGE_firewall4
endef

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

YACD_DASHBOARD_VER=0.3.8

define Package/clash-dashboard
	$(call Package/$(PKG_NAME)/template)
	TITLE:=Web Dashboard for Clash
	URL:=https://github.com/dreamacro/clash-dashboard
	DEPENDS:=$(PKG_NAME)
	PKGARCH:=all
	VERSION:=$(YACD_DASHBOARD_VER)
endef

define Package/clash-dashboard/description
	Web Dashboard for Clash
endef

COUNTRY_MMDB_VER=20230612
COUNTRY_MMDB_FILE:=Country.$(COUNTRY_MMDB_VER).mmdb

define Download/country_mmdb
	URL:=https://github.com/Dreamacro/maxmind-geoip/releases/download/$(COUNTRY_MMDB_VER)/
	URL_FILE:=Country.mmdb
	FILE:=$(COUNTRY_MMDB_FILE)
	HASH:=b83f94ccc8e942fb8d31c2319b88872e72708715ecb44dd6fb4c42b9ff63fe2f
endef

define Download/clash-dashboard
	URL:=https://github.com/haishanh/yacd/releases/download/v$(YACD_DASHBOARD_VER)/
	URL_FILE:=yacd.tar.xz
	FILE:=yacd.tar.xz
	HASH:=d5d7ecde91a708a79386116753e32a59f32c8cb8eec80ded56c3ab94e511ba50
endef


define Build/Prepare
	$(call Build/Prepare/Default)
	$(call Download,country_mmdb)
	$(call Download,clash-dashboard)

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

define Package/clash-dashboard/install
	$(INSTALL_DIR) $(1)/www/clash-dashboard/
	$(TAR) -C $(DL_DIR) -Jxvf $(DL_DIR)/yacd.tar.xz
	$(CP) \
		$(DL_DIR)/public/assets \
		$(DL_DIR)/public/index.html \
		$(DL_DIR)/public/registerSW.js \
		$(DL_DIR)/public/sw.js \
		$(DL_DIR)/public/yacd-128.png \
		$(DL_DIR)/public/yacd-64.png \
		$(DL_DIR)/public/yacd.ico \
		$(DL_DIR)/public/_headers \
		$(1)/www/clash-dashboard/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
