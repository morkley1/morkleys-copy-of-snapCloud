-- Database migrations
-- ===================
--
-- Run migrations by running bin/migrations.sh
--
-- Do not modify a migration once it has been run or commited!
-- To change what a migration does, create a new one.
--
-- Add a new migration with the key 'YYYY-MM-DD:X'
-- Where X is a value [0-9]
-- NOTES:
-- use _at for timestamps, and always add { timezone = true }
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types

-- You MUST recreate the views modifying the users table.
local update_user_views = function ()
    db.query([[
        CREATE OR REPLACE VIEW active_users AS (
            SELECT * FROM users WHERE deleted is null
        )
    ]])
    db.query([[
        CREATE OR REPLACE VIEW deleted_users AS (
            SELECT * FROM users WHERE deleted is not null
        )
    ]])
end

local update_project_views = function ()
    db.query([[
        CREATE OR REPLACE VIEW active_projects AS (
            SELECT * FROM projects WHERE deleted is null
        )
    ]])
    db.query([[
        CREATE OR REPLACE VIEW deleted_projects AS (
            SELECT * FROM projects WHERE deleted is not null
        )
    ]])
end

return {
    -- TODO: We will eventually create migrations for the other tables.

    -- Create Collections and CollectionMemberships
    ['2019-01-04:0'] = function ()
        schema.create_table("collections", {
            { 'id', types.serial({ primary_key = true }) },
            { 'name', types.text },
            { 'creator_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            { 'description', types.text({ null = true }) },
            { 'published', types.boolean },
            { 'published_at', types.time({ timezone = true, null = true }) },
            { 'shared', types.boolean },
            { 'shared_at', types.time({ timezone = true, null = true }) },
            { 'thumbnail_id', types.foreign_key({ null = true }) }
        })
        schema.create_index('collections', 'creator_id')

        schema.create_table("collection_memberships", {
            { 'id', types.serial({ primary_key = true }) },
            { 'collection_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })
        schema.create_index('collection_memberships', 'collection_id')
        schema.create_index('collection_memberships', 'project_id')
    end,

    -- Update CollectionMemberships to store a user
    ['2019-01-29:0'] = function ()
        schema.add_column(
            'collection_memberships', 'user_id', types.foreign_key
        )
        schema.create_index('collection_memberships',
                            'collection_id', 'project_id', 'user_id',
                            { unique = true })
    end,
    -- Create and views for handling deleted items.
    ['2019-02-01:0'] = function ()
        schema.add_column('users',
                          'deleted',
                          types.time({ timezone = true, null = true }))
        update_user_views()

        schema.add_column('projects',
                          'deleted',
                          types.time({ timezone = true, null = true }))
        update_project_views()
    end,

    -- Add an editor_ids[] field to collections
    ['2019-02-04:0'] = function ()
        schema.add_column(
            'collections',
            'editor_ids',
            types.foreign_key({ array = true, null = true })
        )
    end,

    -- Add a table to store spambot IPs and ban them
    ['2019-02-05:0'] = function ()
        schema.create_table("banned_ips", {
            { 'ip', types.text({ primary_key = true }) },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            { 'offense_count', types.integer, { default = 1 } }
        })
    end,

    ['2020-10-22:0'] = function ()
        schema.add_column('users', 'unique_email', types.text({ null = true, unique = true }))
        -- We use an index on *non-unique* emails to be able to search related accounts.
        -- We will rarely query by unique_email and thus no index is necessary.
        schema.create_index('users', 'email', { unique = false })
        update_user_views()
    end,

    -- Update Collections to include a "free for all" flag
    ['2020-11-03:0'] = function ()
        schema.add_column(
            'collections',
            'free_for_all',
            types.boolean
        )
        -- The "flagged" collection is free for all
        db.update(
            'collections',
            { free_for_all = true },
            { id = 0 }
        )
    end,

    -- Create a FlaggedProjects table
    ['2020-11-09:0'] = function ()
        schema.create_table("flagged_projects", {
            { 'id', types.serial({ primary_key = true }) },
            { 'flagger_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'reason', types.text },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        -- One flag per user and project
        schema.create_index('flagged_projects',
                            'flagger_id', 'project_id',
                            { unique = true })
    end,

    -- Add a notes column to FlaggedProjects
    ['2020-11-10:0'] = function ()
        schema.add_column(
            'flagged_projects',
            'notes',
            types.text({ null = true })
        )
    end,

    -- Contracts Model
    ['2021-08-11:0'] = function ()
        schema.create_table('contracts', {
            { 'id', types.serial({ primary_key = true }) },
            { 'name', types.text },
            { 'start_date', types.date },
            { 'end_date', types.date },
            { 'email_domains', types.text({ array = true }) },
            { 'contact_info', types.text({ null = true }) },
            { 'contact_email', types.text },
            { 'notes', types.text({ null = true }) },
            { 'location', types.text({ null = true}) },
            { 'timezone', types.text({ null = true}) },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        schema.create_table('contract_users', {
            { 'id', types.serial({ primary_key = true }) },
            { 'user_id', types.foreign_key },
            { 'contract_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        db.query([[
            CREATE TYPE contract_role AS ENUM ('admin', 'teacher', 'student');
        ]])

        db.query([[
            ALTER TABLE contract_users ADD COLUMN role contract_role;
            ALTER TABLE contract_users ALTER COLUMN role SET NOT NULL;
            ALTER TABLE contract_users ALTER COLUMN role SET DEFAULT 'student';
        ]])

        schema.create_index('contract_users', 'user_id', 'contract_id', { unique = true });
    end,

    -- Store login, session times on user
    ['2021-08-12:0'] = function ()
        schema.add_column('users', 'last_session_at', types.time({ timezone = true, null = true }))
        schema.add_column('users', 'last_login_at', types.time({ timezone = true, null = true }))

        update_user_views()
    end,

    -- Primarily for analytics.
    ['2021-08-12:1'] = function ()
        schema.create_index('users', 'last_session_at')
    end,

    -- User Identities & OAuth Providers
    -- The basics needed to support external logins.
    ['2021-09-20:1'] = function ()
        -- Notable we will not store access/refresh tokens because we are just authenticating users.
        schema.create_table('identities', {
            { 'id', types.serial({ primary_key = true }) },
            { 'user_id', types.foreign_key },
            { 'provider_id', types.foreign_key },
            { 'uid', types.text },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        schema.create_index('identities', 'user_id', 'provider_id', { unique = true });

        schema.create_table('oauth_providers', {
            { 'id', types.serial({ primary_key = true }) },
            { 'name', types.text },
            { 'short_name', types.text },
            { 'logo_path', types.text },
            { 'client_id', types.text },
            { 'client_secret', types.text },
            { 'authorization_url', types.text },
            { 'scopes', types.text },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        -- Add our jsonb columns which lapis doesn't natively know about.
        db.query([[
            ALTER TABLE identities ADD COLUMN metadata jsonb DEFAULT '{}';
            ALTER TABLE oauth_providers ADD COLUMN config jsonb DEFAULT '{}';
        ]])
    end
}
