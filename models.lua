-- Database abstractions
-- =====================
--
-- A cloud backend for Snap!
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local db = package.loaded.db
local Model = package.loaded.Model

package.loaded.Projects = Model:extend('active_projects', {
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    }
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

package.loaded.Tokens = Model:extend('tokens', {
    primary_key = {'value'}
})

package.loaded.Remixes = Model:extend('remixes', {
    primary_key = {'original_project_id', 'remixed_project_id'}
})

package.loaded.Collections = Model:extend('collections', {
    primary_key = {'creator_id', 'name'},
    timestamp = true,
    relations = {
        -- creates collection:get_creator()
        {'creator', belongs_to = 'Users', key = 'creator_id'},
        {'memberships', has_many = 'CollectionMemberships'},
        {'projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                            AS memberships
                            ON active_projects.id = memberships.project_id
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'shared_and_published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                            AS memberships
                            ON active_projects.id = memberships.project_id
                        WHERE (ispublished OR ispublic)
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                            AS memberships
                            ON active_projects.id = memberships.project_id
                        WHERE ispublished
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        }
    },
    constraints = {
        name = function(self, value)
            if not value then
                return 'A name must be present'
            end
        end
    },
    count_projects = function (self)
        return package.loaded.CollectionMemberships:count('collection_id = ?',
                                                          self.id)
    end
})

package.loaded.CollectionMemberships = Model:extend(
    'collection_memberships', {
        primary_key = {'collection_id', 'project_id'},
        timestamp = true
    }
)

package.loaded.BannedIPs = Model:extend(
    'banned_ips', {
        primary_key = 'ip',
        timestamp = true
    }
)

package.loaded.FlaggedProjects = Model:extend(
    'flagged_projects', {
        primary_key = 'id',
        timestamp = true
    }
)
