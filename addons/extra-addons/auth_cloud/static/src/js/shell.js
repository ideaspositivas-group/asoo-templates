odoo.define('deployment.shell', function (require) {
    var core = require('web.core');
    var config = require('web.config');
    var FormController = require("web.FormController");
    var Dialog = require('web.Dialog');
    var rpc = require('web.rpc');
    var _t = core._t;

    var docCookies = {
        getItem: function (sKey) {
            if (!sKey) {
                return null;
            }
            return decodeURIComponent(document.cookie.replace(new RegExp("(?:(?:^|.*;)\\s*" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*([^;]*).*$)|^.*$"), "$1")) || null;
        },
        setItem: function (sKey, sValue, vEnd, sPath, sDomain, bSecure) {
            if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/i.test(sKey)) {
                return false;
            }
            var sExpires = "";
            if (vEnd) {
                switch (vEnd.constructor) {
                    case Number:
                        sExpires = vEnd === Infinity ? "; expires=Fri, 31 Dec 9999 23:59:59 GMT" : "; max-age=" + vEnd;
                        /*
                        Note: Despite officially defined in RFC 6265, the use of `max-age` is not compatible with any
                        version of Internet Explorer, Edge and some mobile browsers. Therefore passing a number to
                        the end parameter might not work as expected. A possible solution might be to convert the the
                        relative time to an absolute time. For instance, replacing the previous line with:
                        */
                        /*
                        sExpires = vEnd === Infinity ? "; expires=Fri, 31 Dec 9999 23:59:59 GMT" : "; expires=" + (new Date(vEnd * 1e3 + Date.now())).toUTCString();
                        */
                        break;
                    case String:
                        sExpires = "; expires=" + vEnd;
                        break;
                    case Date:
                        sExpires = "; expires=" + vEnd.toUTCString();
                        break;
                }
            }
            document.cookie = encodeURIComponent(sKey) + "=" + encodeURIComponent(sValue) + sExpires + (sDomain ? "; domain=" + sDomain : "") + (sPath ? "; path=" + sPath : "") + (bSecure ? "; secure" : "");
            return true;
        },
        removeItem: function (sKey, sPath, sDomain) {
            if (!this.hasItem(sKey)) {
                return false;
            }
            document.cookie = encodeURIComponent(sKey) + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT" + (sDomain ? "; domain=" + sDomain : "") + (sPath ? "; path=" + sPath : "");
            return true;
        },
        hasItem: function (sKey) {
            if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/i.test(sKey)) {
                return false;
            }
            return (new RegExp("(?:^|;\\s*)" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie);
        },
        keys: function () {
            var aKeys = document.cookie.replace(/((?:^|\s*;)[^\=]+)(?=;|$)|^\s*|\s*(?:\=[^;]*)?(?:\1|$)/g, "").split(/\s*(?:\=[^;]*)?;\s*/);
            for (var nLen = aKeys.length, nIdx = 0; nIdx < nLen; nIdx++) {
                aKeys[nIdx] = decodeURIComponent(aKeys[nIdx]);
            }
            return aKeys;
        }
    };

    FormController.include({
        reload: function () {
            var self = this;
            return this._super.apply(this, arguments)
                .then(function () {
                    return self.startShell();
                });
        },
        start: function () {
            this._super.apply(this, arguments);
            this.startShell()
        },
        startShell: function () {
            var $btn_shell = this.$('.btn-shell');
            if ($btn_shell) {
                if (config.device.isMobile) {
                    $btn_shell.hide();
                } else {
                    $btn_shell.on('click', _.bind(this.openShell, this));
                }
            }
            var $btn_login = this.$('.btn-login');
            $btn_login.on('click', _.bind(this.login, this))
        },
        login: function () {
            console.log('looogin')
            var myDate = new Date();
            myDate.setMonth(myDate.getMonth() + 12);
            docCookies.setItem('aaaa', 'd61160f5806a2638d939d99c1639d4d9cf5709fd', myDate, '/', '.aselcis.com');
            console.log('qqqqewewewe')
        },
        openShell: function () {
            var record = this.model.get(this.handle);
            new ShellDialog(this, record.res_id, record.data.display_name || record.data.name).open();
        }
    });


    var ShellDialog = Dialog.extend({
        template: 'deployment.server_shell_dialog',
        init: function (parent, server_id, display_name) {
            var self = this;
            this.server_id = server_id;
            this.server_name = display_name;
            this.parent = parent;
            var options = {
                title: _.str.sprintf(_t("Shell of %s"), this.server_name),
                size: 'large'
            };
            this._super(parent, options);
            this._opened.then(function () {
                self.$el.closest('.modal').addClass('shell-dialog');
                if (!self.url) {
                    self.close();
                }
            });
        },
        willStart: function () {
            var self = this;
            return this._super.apply(this, arguments)
                .then(function () {
                    return self.getAccessToken()
                });
        },
        getAccessToken: function () {
            var self = this;
            return rpc.query({route: '/deployment/shell/access_token', params: {server_id: this.server_id}})
                .then(function (result) {
                    self.url = result;
                    if (!result) {
                        self.trigger_up('warning', {
                            message: _.str.sprintf(_t('System can not connect with %s'), self.server_name),
                            title: _t('Not SSH connection')
                        });
                    }
                })
        }
    });


});