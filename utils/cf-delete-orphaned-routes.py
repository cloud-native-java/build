#!/usr/bin/env python

import requests
import sys


def cf_delete_orphaned_route_service_routes(token):
    print 'inside cf_delete_orphaned_route_service_routes with token %s' % token

    auth_header = {'Authorization': token}
    root_uri = 'http://api.run.pivotal.io%s'

    def merge_routes_with_guid(routes):
        routes = routes['resources']
        routes = [(r1['metadata']['guid'], r1['entity']) for r1 in routes]
        n_routes = []
        for guid, entity in routes:
            d = {}
            d['guid'] = guid
            for k, v in entity.iteritems():
                d[k] = v
            n_routes.append(d)
        return n_routes

    routes = requests.get(root_uri % '/v2/routes', headers=auth_header).json()
    routes = merge_routes_with_guid(routes)
    routes_with_svs = [r for r in routes if r['service_instance_guid'] != None]
    for r in routes_with_svs:
        apps_url = r['apps_url']
        si_guid = r['service_instance_guid']
        r_guid = r['guid']
        apps = requests.get(root_uri % apps_url, headers=auth_header).json()
        if apps['total_results'] == 0:
            # if a route is not mapped to any apps, but is bound to a service instance, it's orphaned.
            cf_curl = '/v2/service_instances/%s/routes/%s' % (si_guid, r_guid)
            url_to_unbind = root_uri % cf_curl
            print 'calling DELETE on %s' % url_to_unbind
            requests.delete(url_to_unbind, headers=auth_header)


if __name__ == '__main__':
    # ./cf-delete-orphaned-routes.py "`cf oauth-token`"

    token = ' '.join(sys.argv[1:])
    cf_delete_orphaned_route_service_routes(token)
