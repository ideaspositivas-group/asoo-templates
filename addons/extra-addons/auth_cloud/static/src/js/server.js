odoo.define('deployment.server', function (require) {
    var core = require('web.core');
    var KanbanController = require("web.KanbanController");
    var _t = core._t;

    KanbanController.include({
        renderButtons: function () {
            this._super.apply(this, arguments);
            var self = this;

            if (this.modelName === 'server.server') {
                this.$buttons.find('button.o_button_import').remove();
                this.$buttons.find('button.o-kanban-button-new')
                    .text(_t("Deploy server"))
                    .off("click")
                    .on("click", function (e) {
                        e.preventDefault();
                        e.stopImmediatePropagation();
                        self.do_action("deployment.action_wiz_server_deploy");
                    });
            }
        }
    });
});