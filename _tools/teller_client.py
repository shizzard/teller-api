#!/usr/bin/env python

import argparse
import sys
import requests
from requests.auth import HTTPBasicAuth
from xmlrpc.client import boolean


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='Perform Teller API request.',
        epilog="""Resources:
    root            GET /
    fake            GET /fake
    accs            GET /accounts
    acc_id          GET /accounts/:account_id
    acc_details     GET /accounts/:account_id/details
    acc_balances    GET /accounts/:account_id/balances
    acc_trxs        GET /accounts/:account_id/transactions
    acc_trx_id      GET /accounts/:account_id/transactions/:transaction_id
        """)
    parser.add_argument(
        '-v', action="store_true", help='Verbose mode (use with LUX tests)')
    parser.add_argument(
        '--resource', required=True,
        choices=['root', 'fake', 'accs', 'acc_id', 'acc_details',
                 'acc_balances', 'acc_trxs', 'acc_trx_id'],
        help='Choose a resource to reform a request to')
    parser.add_argument('--proto', default="https", nargs='?',
                        help='Teller API proto')
    parser.add_argument('--host', default="api.teller.io", nargs='?',
                        help='Teller API host')
    parser.add_argument('--port', default="", nargs='?',
                        help='Teller API port (:8080)')
    parser.add_argument('--token', nargs='?', help='Teller API auth token')
    parser.add_argument('--account', nargs='?', help='Teller API account_id')
    parser.add_argument('--transaction', nargs='?',
                        help='Teller API transaction_id')
    parser.add_argument('--count', nargs='?',
                        help='Transactions count request parameter (applies to acc_trxs resource)')
    parser.add_argument('--from_id', nargs='?',
                        help='Transactions from_id request parameter (applies to acc_trxs resource)')

    ns = parser.parse_args(sys.argv[1:])
    perform_request(ns)


def perform_request(ns):
    uri = uri_map()[ns.resource].format(args=ns)
    params = get_params(ns)
    auth = basic_auth(ns)
    r = requests.get(uri, params=params, auth=auth)
    print_response(r, ns)


def print_response(r, ns):
    ns.v and print(">>> RESPONSE")
    print_response_code(r, ns)
    print_response_headers(r, ns)
    print_response_body(r, ns)
    ns.v and print("<<< RESPONSE")


def print_response_code(r, ns):
    ns.v and print(">>> CODE")
    print(r.status_code)
    ns.v and print("<<< CODE")


def print_response_headers(r, ns):
    ns.v and print(">>> HEADERS")
    for header in r.headers:
        print(header, ":", r.headers[header])
    ns.v and print("<<< HEADERS")


def print_response_body(r, ns):
    ns.v and print(">>> BODY")
    body = r.json()
    if type(body) == list:
        ns.v and print(">>> LIST {}".format(len(body)))
        for object in body:
            ns.v and print(">>> OBJECT")
            print_response_body_object(object)
            ns.v and print("<<< OBJECT")
            print()
        ns.v and print("<<< LIST")
    else:
        ns.v and print(">>> OBJECT")
        print_response_body_object(body)
        ns.v and print("<<< OBJECT")
        print()
    ns.v and print("<<< BODY")


def print_response_body_object(object, prefix=[]):
    for key in object:
        if type(object[key]) == dict:
            print_response_body_object(object[key], prefix + [key])
        else:
            print("_".join(prefix + [key]), ":", object[key])


def uri_map():
    return {
        'root': '{args.proto}://{args.host}{args.port}/',
        'fake': '{args.proto}://{args.host}{args.port}/fake',
        'accs': '{args.proto}://{args.host}{args.port}/accounts',
        'acc_id': '{args.proto}://{args.host}{args.port}/accounts/{args.account}',
        'acc_details': '{args.proto}://{args.host}{args.port}/accounts/{args.account}/details',
        'acc_balances': '{args.proto}://{args.host}{args.port}/accounts/{args.account}/balances',
        'acc_trxs': '{args.proto}://{args.host}{args.port}/accounts/{args.account}/transactions',
        'acc_trx_id': '{args.proto}://{args.host}{args.port}/accounts/{args.account}/transactions/{args.transaction}'
    }


def get_params(ns):
    ret = {}
    if ns.count != None:
        ret['count'] = ns.count
    if ns.from_id != None:
        ret['from_id'] = ns.from_id
    return ret


def basic_auth(ns):
    if ns.token != None:
        return HTTPBasicAuth(ns.token, '')
    else:
        return None


if __name__ == "__main__":
    main()
