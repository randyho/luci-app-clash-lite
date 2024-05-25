"use strict";
"require form";
'require poll';
"require view";
"require uci";
"require ui";
"require rpc";
"require fs";

var callGetStatus = rpc.declare({
  object: "luci.clash",
  method: "get_status",
  expect: {  }
});

var callGetVersion = rpc.declare({
  object: "luci.clash",
  method: "get_version",
  expect: {  }
});

var callRemoveArgon = rpc.declare({
  object: 'luci.clash',
  method: 'remove',
  params: ['filename'],
  expect: { '': {} }
});


// var handleOpenDashboard: function () {
//   var path = "clash-dashboard";
//   var host = window.location.host;
//   var protocol = window.location.protocol;
//   window.open("%s//%s/%s?hostname=%s".format(protocol, host, path, host));
// };

function renderStatus(isRunning, port) {
  console.log(isRunning)
  var spanTemp = '<span style="color:%s"><strong>%s %s</strong></span>';
  var renderHTML;
  if (isRunning) {
    var button = String.format('&#160;<a class="btn cbi-button" href="http://%s:%s" target="_blank" rel="noreferrer noopener">%s</a>',
      window.location.hostname, port, _('Open Dashboard'));
    renderHTML = spanTemp.format('green', _('Clash Core is'), _('RUNNING')) + button;
  } else {
    renderHTML = spanTemp.format('red', _('Clash Core is'), _('NOT RUNNING'));
  }

  return renderHTML;
}

var config_path = '/etc/clash/config/';

return view.extend({
  load: function () {
    return Promise.all([
      uci.load('clash'),
      L.resolveDefault(callGetStatus(), {}),
      L.resolveDefault(fs.list(config_path), {})
    ]);
  },

  render: function (data) {
    var _this = this;
    console.log(data)
    var version = data[1];
    var m, s, o;

    m = new form.Map(
      "clash",
      _("Clash Lite"),
      _("A Clash Client For OpenWrt")
    );

    // 状态
    s = m.section(form.TypedSection);
    s.anonymous = true;
    s.render = function () {
        poll.add(function () {
        return L.resolveDefault(callGetStatus(), {}).then(function (res) {
            var view = document.getElementById('service_status');
            view.innerHTML = renderStatus(res, 9090);
        });
        });

      return E('div', { class: 'cbi-section', id: 'status_bar' }, [
          E('p', { id: 'service_status' }, _('Collecting data...'))
      ]);
    }

    // 设置
    s = m.section(form.TypedSection, 'global', _('Core Settings'));
    s.anonymous = true;

    o = s.option(form.Flag, 'enabled', _('Enable'));
    o.default = o.disabled;
    o.rmempty = false;

    o = s.option(form.Value, 'blur', _('Mixed Port'), _(' "The port of http and socks proxy server.'));
    o.datatype = 'port';
    o.default = 7890;
    o.rmempty = false;

    o = s.option(form.ListValue, 'mode', _('Proxy mode'));
    o.value("direct", "Direct");
    o.value("rule", "Rule");
    o.value("global", "Global");
    o.default = 'Rule';
    o.rmempty = false;

    o = s.option(form.ListValue, 'log_level', _('Log Level'));
    o.value("silent", "Silent");
    o.value("debug", "Debug");
    o.value("info", "Info");
    o.value("warning", "Warning");
    o.value("error", "Error");
    o.default = 'Info';
    o.rmempty = false;

    o = s.option(form.ListValue, "core_arch", _("Core Arch"));
    o.value("linux-amd64", "linux-amd64");
    o.value("linux-amd64-v3", "linux-amd64-v3");
    o.value("inux-armv5", "inux-armv5");
    o.value("linux-armv6", "linux-armv6");
    o.value("linux-armv7", "linux-armv7");
    o.value("linux-arm64", "linux-arm64");
    o.value("linux-mips-hardfloat", "linux-mips-hardfloat");
    o.value("linux-mips-softfloat", "linux-mips-softfloat");
    o.value("linux-mips64", "linux-mips64");
    o.value("linux-mipsle-hardfloat", "linux-mipsle-hardfloat");
    o.value("linux-mipsle-softfloat", "linux-mipsle-softfloat");
    o.rmempty = false;

    o = s.option(form.DummyValue, "_version", _("Version"));
    o.cfgvalue = function () {
      return _(version);
    };

    o = s.option(form.Button, '_update_core', _('Update Core'));
    o.inputstyle = 'add';
    o.onclick = function () {
    var _this = this;
    return fs.exec('/usr/share/clash/update_core.sh').then(function (res) {
        if (res.code === 0)
          _this.description = _('Update successful');
        else if (res.code === 1)
          _this.description = _('Update failed');
        return _this.map.reset();
      }).catch(function (err) {
        ui.addNotification(null, E('p', [_('Unknown error: %s.').format(err)]));
        _this.description = _('Update failed');
        return _this.map.reset();
      });
    }

    o = s.option(form.Button, '_update_geoip', _('Update GeoIP'));
    o.inputstyle = 'add';
    o.onclick = function () {
    var _this = this;
    return fs.exec('/usr/share/clash/update_geoip.sh').then(function (res) {
        if (res.code === 0)
            _this.description = _('Update successful');
        else if (res.code === 1)
            _this.description = _('Update failed');
        return _this.map.reset();
        }).catch(function (err) {
        ui.addNotification(null, E('p', [_('Unknown error: %s.').format(err)]));
        _this.description = _('Update failed');
        return _this.map.reset();
        }
      );
    }

    o = s.option(form.Button, '_save', _('Save settings'));
    o.inputstyle = 'apply';
    o.inputtitle = _('Save current settings');
    o.onclick = function() {
    ui.changes.apply(true);
      return this.map.save(null, true);
    }

    o = s.option(form.Button, "_restart", _("Service"));
    o.inputtitle = _("Restart");
    o.inputstyle = "apply";
    o.onclick = function () {
      return _this
        .callInitAction("clash", "restart")
        .then(L.bind(m.load, m))
        .then(L.bind(m.render, m));
    };

    // Upload Profile
    s = m.section(form.TypedSection, null, _('Upload Profile'), _('You can upload yaml profile here.'));
    s.addremove = false;
    s.anonymous = true;

    o = s.option(form.Button, '_upload_profile', _('Upload Profile'), _('Files will be uploaded to <code>%s</code>.').format(config_path));
    o.inputstyle = 'action';
    o.inputtitle = _('Upload...');
    o.onclick = function(ev, section_id) {
      var file = '/tmp/clash_profile.tmp';
      return ui.uploadFile(file, ev.target).then(function(res) {
        return L.resolveDefault(callRenameArgon(res.name), {}).then(function(ret) {
          if (ret.result === 0)
            return location.reload();
          else {
            ui.addNotification(null, E('p', _('Failed to upload file: %s.').format(res.name)));
            return L.resolveDefault(fs.remove(file), {});
          }
        });
      })
      .catch(function(e) { ui.addNotification(null, E('p', e.message)); });
    };
    o.modalonly = true;

    // profile list
    s = m.section(form.TableSection);
    s.render = function() {
      var tbl = E('table', { 'class': 'table cbi-section-table' },
        E('tr', { 'class': 'tr table-titles' }, [
          E('th', { 'class': 'th' }, [ _('Filename') ]),
          E('th', { 'class': 'th' }, [ _('Modified date') ]),
          E('th', { 'class': 'th' }, [ _('Size') ]),
          E('th', { 'class': 'th' }, [ _('Action') ])
        ])
      );

      cbi_update_table(tbl, data[2].map(L.bind(function(file) {
        return [
          file.name,
          new Date(file.mtime * 1000).toLocaleString(),
          String.format('%1024.2mB', file.size),
          E('button', {
            'class': 'btn cbi-button cbi-button-remove',
            'click': ui.createHandlerFn(this, function() {
              return L.resolveDefault(callRemoveArgon(file.name), {})
              .then(function() { return location.reload(); });
            })
          }, [ _('Delete') ])
        ];
      }, this)), E('em', _('No files found.')));

      return E('div', { 'class': 'cbi-map', 'id': 'cbi-filelist' }, [
        E('h3', _('Profile List')),
        tbl
      ]);
    };

    return m.render();
  },

  handleSave: null,
  handleSaveApply: null,
  handleReset: null
});
