# -*- coding: utf-8 -*-
from odoo import fields, models
from odoo.exceptions import AccessDenied


class ResUsers(models.Model):
    _inherit = 'res.users'

    authenticator_token = fields.Char('Authenticator token')
    authenticator_expire_in = fields.Datetime('Authenticator token expire in')

    def _check_credentials(self, password, env):
        try:
            super(ResUsers, self)._check_credentials(password, env)
        except AccessDenied:
            user = self.sudo().search([
                ('id', '=', self._uid),
                ('authenticator_token', '=', password)
            ])
            if not user:
                raise AccessDenied()
