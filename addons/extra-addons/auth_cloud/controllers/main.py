# -*- coding: utf-8 -*-
import werkzeug
import uuid
from datetime import datetime, timedelta

from odoo import exceptions, fields, SUPERUSER_ID, api, _
from odoo.addons.web.controllers.main import ensure_db, set_cookie_and_redirect, login_and_redirect
from odoo import registry as registry_get
from odoo.tools import config
from odoo.exceptions import AccessDenied
from odoo.http import request, route, Controller

TOKENS = {}


class Authenticator(Controller):

    @route("/_auth/info", type="json", auth="none")
    def info(self, db, admin_passwd):
        if not config.verify_admin_password(admin_passwd):
            raise AccessDenied()

        registry = registry_get(db)
        with registry.cursor() as cr:
            env = api.Environment(cr, SUPERUSER_ID, {})
            users = env['res.users'].sudo().search_read([
                ('share', '=', False)
            ], ['id', 'login', 'name', 'groups_id'])
            ResGroups = env['res.groups']
            IrModelData = env['ir.model.data']
            admin_group_id = env.ref('base.group_erp_manager').id

            group_ids = []
            for app, kind, gs in ResGroups.sudo().get_groups_by_application():
                if kind == 'selection':
                    group_ids.extend(gs.ids)

            for user in users:
                # TODO: Implement user lang to translate groups names
                category_ids = []
                user['groups_id'] = ResGroups.sudo().search_read([
                    ('id', 'in', [
                     g for g in user['groups_id'] if g in group_ids])
                ], ['id', 'full_name', 'category_id'], order='id desc')
                user['is_admin'] = True if admin_group_id in [g['id']
                                                              for g in user['groups_id']] else False
                user_groups_id = []
                for group in user['groups_id']:
                    if group['category_id'][0] not in category_ids:
                        group_info = IrModelData.sudo().search_read([
                            ('model', '=', 'res.groups'),
                            ('res_id', '=', group.get('id'))
                        ], ['module', 'name'], order='id', limit=1)
                        group['external_id'] = '{}.{}'.format(
                            group_info[0]['module'], group_info[0]['name']) if group_info else False
                        category_ids.append(group['category_id'][0])
                        user_groups_id.append(group)
                user['groups_id'] = user_groups_id
        return users

    @route("/_auth/token", type="json", auth="none")
    def token(self, db, admin_passwd, login):
        if not config.verify_admin_password(admin_passwd):
            raise AccessDenied()

        registry = registry_get(db)
        with registry.cursor() as cr:
            env = api.Environment(cr, SUPERUSER_ID, {})
            token = uuid.uuid4()
            user = env['res.users'].sudo().search([('login', '=', login)])
            user.write({
                'authenticator_token': token,
                'authenticator_expire_in': datetime.now() + timedelta(seconds=30)
            })
        return token

    @route("/_auth/access", type="http", auth="none")
    def access(self, **kw):
        token = kw.get('token')
        db = kw.get('db')
        registry = registry_get(db)
        with registry.cursor() as cr:
            env = api.Environment(cr, SUPERUSER_ID, {})
            user = env['res.users'].sudo().search([
                ('authenticator_token', '=', token)
            ])
            if not user:
                raise AccessDenied()

            # Check if expire
            if fields.Datetime.from_string(user.authenticator_expire_in) < datetime.now():
                raise AccessDenied()

            redirect = login_and_redirect(
                db, user.login, user.authenticator_token)
            user.write({'authenticator_token': False,
                        'authenticator_expire_in': False})
            cr.commit()
            return redirect
        return set_cookie_and_redirect('/web')
