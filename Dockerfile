FROM debian:stretch
LABEL maintainer="Ideas Positivas <www.ideaspositivas.es>"

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            dirmngr \
            fonts-noto-cjk \
            gnupg \
            libssl1.0-dev \
            node-less \
            python3-pip \
            python3-pyldap \
            python3-qrcode \
            python3-renderpm \
            python3-setuptools \
            python3-vobject \
            python3-watchdog \
            xz-utils \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb\
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --armor --export "${repokey}" | apt-key add - \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian stretch)
RUN set -x;\
    echo "deb http://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && export GNUPGHOME="$(mktemp -d)" \
    && repokey='9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --armor --export "${repokey}" | apt-key add - \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g rtlcss \
    && rm -rf /var/lib/apt/lists/*

# Install Odoo
ENV ODOO_VERSION 12.0
ARG ODOO_RELEASE=20200501
ARG ODOO_SHA=b1fdaa4d0d541f302c90a10a128979af5efe10d1
RUN set -x; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Install python requirements.txt
ADD ./requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt 

# Replace Odoo files /usr/lib/python3/dist-packages/odoo
# -- account_facturx --
COPY ./odoo/addons/account_facturx/models/account_invoice.py /usr/lib/python3/dist-packages/odoo/addons/account_facturx/models/
# -- base_geolocalize --
COPY ./odoo/addons/base_geolocalize/views/res_partner_views.xml /usr/lib/python3/dist-packages/odoo/addons/base_geolocalize/views/
# -- bus --
COPY ./odoo/addons/bus/static/src/js/services/bus_service.js /usr/lib/python3/dist-packages/odoo/addons/bus/static/src/js/services/
# -- calendar --
COPY ./odoo/addons/calendar/models/calendar.py /usr/lib/python3/dist-packages/odoo/addons/calendar/models/
# -- crm --
COPY ./odoo/addons/crm/data/crm_stage_data.xml /usr/lib/python3/dist-packages/odoo/addons/crm/data/
COPY ./odoo/addons/crm/i18n/es.po /usr/lib/python3/dist-packages/odoo/addons/crm/i18n/
COPY ./odoo/addons/crm/models/crm_lead.py /usr/lib/python3/dist-packages/odoo/addons/crm/models/
COPY ./odoo/addons/crm/models/crm_stage.py /usr/lib/python3/dist-packages/odoo/addons/crm/models/
COPY ./odoo/addons/crm/views/crm_lead_views.xml /usr/lib/python3/dist-packages/odoo/addons/crm/views/
# -- crm_phone_validation --
COPY ./odoo/addons/crm_phone_validation/__init__.py /usr/lib/python3/dist-packages/odoo/addons/crm_phone_validation/
# -- hr_expense --
COPY ./odoo/addons/hr_expense/models/hr_expense.py /usr/lib/python3/dist-packages/odoo/addons/hr_expense/models/
# -- hr_timesheet --
COPY ./odoo/addons/hr_timesheet/models/analytic_account.py /usr/lib/python3/dist-packages/odoo/addons/hr_timesheet/models/
# -- hw_drivers --
COPY ./odoo/addons/hw_drivers/controllers/driver.py /usr/lib/python3/dist-packages/odoo/addons/hw_drivers/controllers/
# -- l10n_ch --
COPY ./odoo/addons/l10n_ch/models/account_invoice.py /usr/lib/python3/dist-packages/odoo/addons/l10n_ch/models/
# -- link_tracker --
COPY ./odoo/addons/link_tracker/views/link_tracker.xml /usr/lib/python3/dist-packages/odoo/addons/link_tracker/views/
# -- mail --
COPY ./odoo/addons/mail/models/mail_activity.py /usr/lib/python3/dist-packages/odoo/addons/mail/models/
COPY ./odoo/addons/mail/models/mail_mail.py /usr/lib/python3/dist-packages/odoo/addons/mail/models/
COPY ./odoo/addons/mail/models/mail_message.py /usr/lib/python3/dist-packages/odoo/addons/mail/models/mail_message.py
COPY ./odoo/addons/mail/models/mail_thread.py /usr/lib/python3/dist-packages/odoo/addons/mail/models/mail_thread.py
COPY ./odoo/addons/mail/models/res_partner.py /usr/lib/python3/dist-packages/odoo/addons/mail/models/res_partner.py
COPY ./odoo/addons/mail/static/src/js/discuss.js /usr/lib/python3/dist-packages/odoo/addons/mail/static/src/js/discuss.js
COPY ./odoo/addons/mail/static/src/js/systray/systray_activity_menu.js /usr/lib/python3/dist-packages/odoo/addons/mail/static/src/js/systray/systray_activity_menu.js
COPY ./odoo/addons/mail/wizard/mail_compose_message_view.xml /usr/lib/python3/dist-packages/odoo/addons/mail/wizard/mail_compose_message_view.xml
# -- maintenance --
COPY ./odoo/addons/maintenance/models/maintenance.py /usr/lib/python3/dist-packages/odoo/addons/maintenance/models/maintenance.py
# -- mass_mailing --
COPY ./odoo/addons/mass_mailing/models/mail_thread.py /usr/lib/python3/dist-packages/odoo/addons/mass_mailing/models/mail_thread.py
COPY ./odoo/addons/mass_mailing/static/src/js/unsubscribe.js /usr/lib/python3/dist-packages/odoo/addons/mass_mailing/static/src/js/unsubscribe.js
# -- portal --
COPY ./odoo/addons/portal/wizard/portal_wizard_views.xml /usr/lib/python3/dist-packages/odoo/addons/portal/wizard/portal_wizard_views.xml
# -- pos_discount --
COPY ./odoo/addons/pos_discount/static/src/js/discount.js /usr/lib/python3/dist-packages/odoo/addons/pos_discount/static/src/js/discount.js
# -- product --
COPY ./odoo/addons/product/models/res_config_settings.py /usr/lib/python3/dist-packages/odoo/addons/product/models/res_config_settings.py
COPY ./odoo/addons/product/views/product_views.xml /usr/lib/python3/dist-packages/odoo/addons/product/views/product_views.xml
# -- purchase --
COPY ./odoo/addons/purchase/views/purchase_views.xml /usr/lib/python3/dist-packages/odoo/addons/purchase/views/purchase_views.xml
# -- sale --
COPY ./odoo/addons/sale/models/res_config_settings.py /usr/lib/python3/dist-packages/odoo/addons/sale/models/res_config_settings.py
COPY ./odoo/addons/sale/views/sale_views.xml /usr/lib/python3/dist-packages/odoo/addons/sale/views/sale_views.xml
# -- sms --
COPY ./odoo/addons/sms/wizard/send_sms_views.xml /usr/lib/python3/dist-packages/odoo/addons/sms/wizard/send_sms_views.xml
# -- test_mail --
COPY ./odoo/addons/test_mail/tests/common.py /usr/lib/python3/dist-packages/odoo/addons/test_mail/tests/common.py
# -- web --
COPY ./odoo/addons/web/controllers/main.py /usr/lib/python3/dist-packages/odoo/addons/web/controllers/main.py
COPY ./odoo/addons/web/static/lib/fullcalendar/js/fullcalendar.js /usr/lib/python3/dist-packages/odoo/addons/web/static/lib/fullcalendar/js/fullcalendar.js
COPY ./odoo/addons/web/static/lib/underscore.string/lib/underscore.string.js /usr/lib/python3/dist-packages/odoo/addons/web/static/lib/underscore.string/lib/underscore.string.js
COPY ./odoo/addons/web/static/src/js/core/py_utils.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/core/py_utils.js
COPY ./odoo/addons/web/static/src/js/views/calendar/calendar_controller.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/views/calendar/calendar_controller.js
COPY ./odoo/addons/web/static/src/js/views/calendar/calendar_renderer.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/views/calendar/calendar_renderer.js
COPY ./odoo/addons/web/static/src/js/views/form/form_renderer.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/views/form/form_renderer.js
COPY ./odoo/addons/web/static/src/js/views/kanban/kanban_renderer.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/views/kanban/kanban_renderer.js
COPY ./odoo/addons/web/static/src/js/views/search/search_inputs.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/views/search/search_inputs.js
COPY ./odoo/addons/web/static/src/js/widgets/data_export.js /usr/lib/python3/dist-packages/odoo/addons/web/static/src/js/widgets/data_export.js
COPY ./odoo/addons/web/static/src/scss/web_calendar.scss /usr/lib/python3/dist-packages/odoo/addons/web/static/src/scss/web_calendar.scss
# -- web_editor --
COPY ./odoo/addons/web_editor/models/ir_ui_view.py /usr/lib/python3/dist-packages/odoo/addons/web_editor/models/ir_ui_view.py
COPY ./odoo/addons/web_editor/static/src/js/widgets/widgets.js /usr/lib/python3/dist-packages/odoo/addons/web_editor/static/src/js/widgets/widgets.js
# -- website --
COPY ./odoo/addons/website/models/res_users.py /usr/lib/python3/dist-packages/odoo/addons/website/models/res_users.py
COPY ./odoo/addons/website/models/website.py /usr/lib/python3/dist-packages/odoo/addons/website/models/website.py
COPY ./odoo/addons/website/views/website_views.xml /usr/lib/python3/dist-packages/odoo/addons/website/views/website_views.xml
# -- website_sale --
COPY ./odoo/addons/website_sale/models/product.py /usr/lib/python3/dist-packages/odoo/addons/website_sale/models/product.py
COPY ./odoo/addons/website_sale/views/templates.xml /usr/lib/python3/dist-packages/odoo/addons/website_sale/views/templates.xml
# -- base --
COPY ./odoo/odoo/addons/base/__manifest__.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/__manifest__.py
COPY ./odoo/odoo/addons/base/models/ir_cron.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_cron.py
COPY ./odoo/odoo/addons/base/models/ir_mail_server.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_mail_server.py
COPY ./odoo/odoo/addons/base/models/ir_model.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_model.py
COPY ./odoo/odoo/addons/base/models/ir_module.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_module.py
COPY ./odoo/odoo/addons/base/models/ir_translation.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_translation.py
COPY ./odoo/odoo/addons/base/models/ir_ui_menu.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_ui_menu.py
COPY ./odoo/odoo/addons/base/models/ir_ui_view.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/ir_ui_view.py
COPY ./odoo/odoo/addons/base/models/res_users.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/models/res_users.py
COPY ./odoo/odoo/addons/base/security/base_groups.xml /usr/lib/python3/dist-packages/odoo/odoo/addons/base/security/base_groups.xml
COPY ./odoo/odoo/addons/base/views/ir_actions_views.xml /usr/lib/python3/dist-packages/odoo/odoo/addons/base/views/ir_actions_views.xml
COPY ./odoo/odoo/addons/base/views/ir_cron_views.xml /usr/lib/python3/dist-packages/odoo/odoo/addons/base/views/ir_cron_views.xml
COPY ./odoo/odoo/addons/base/wizard/base_partner_merge.py /usr/lib/python3/dist-packages/odoo/odoo/addons/base/wizard/base_partner_merge.py
# -- odoo/models.py --
COPY ./odoo/odoo/models.py /usr/lib/python3/dist-packages/odoo/odoo/models.py

# Copy entrypoint script and Odoo configuration file
RUN pip3 install num2words xlwt
COPY ./entrypoint.sh /
COPY ./config/odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
