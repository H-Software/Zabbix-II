#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Adrien Pujol - http://www.crashdump.fr/"
__copyright__ = "Copyright 2013, Adrien Pujol"
__license__ = "Mozilla Public License"
__version__ = "0.3"
__email__ = "adrien.pujol@crashdump.fr"
__status__ = "Development"
__doc__ = "Check a TLS certificate validity."

import argparse
import socket
from datetime import datetime
import time
try:
    # Try to load pyOpenSSL first
    # aptitude install python-dev && pip install pyopenssl
    from OpenSSL import SSL
    from pyasn1.codec.der import decoder as der_decoder
    from ndg.httpsclient.subj_alt_name import SubjectAltName
    PYOPENSSL = True
except ImportError:
    # Else, fallback on standard ssl lib (doesn't support SNI)
    import ssl
    PYOPENSSL = False

#CA_CERTS = "/etc/ssl/certs/ca-certificates.crt"
CA_CERTS = "/etc/ssl/certs/ca-bundle.trust.crt"
#CA_CERTS = "/etc/ssl/certs/ca-bundle.crt"

def exit_error(errcode, errtext):
    print errtext
    exit(errcode)

def pyopenssl_check_callback(connection, x509, errnum, errdepth, ok):
    ''' callback for pyopenssl ssl check'''
    #if x509.get_subject().commonName:
    if pyopenssl_check_hostname(x509, HOST):
        if x509.has_expired():
            #exit_error(1, 'Error: Certificate has expired!')
            exit_error(1, '-0.909')
        else:
            print pyopenssl_check_expiration(x509.get_notAfter())

    if not ok:
        return False
    return ok


def pyopenssl_check_expiration(asn1):
    ''' Return the numbers of day before expiration. False if expired.'''
    try:
        expire_date = datetime.strptime(asn1, "%Y%m%d%H%M%SZ")
    except:
        #exit_error(1, 'Certificate date format unknow.')
        exit_error(1, '-0.988')

    expire_in = expire_date - datetime.now()
    if expire_in.days > 0:
        return expire_in.days
    else:
        return False


def pyssl_check_hostname(cert, hostname):
    ''' Return True if valid. False is invalid '''
    if 'subjectAltName' in cert:
        for typ, val in cert['subjectAltName']:
            # Wilcard
            if typ == 'DNS' and val.startswith('*'):
                if val[2:] == hostname.split('.', 1)[1]:
                    return True
            # Normal hostnames
            elif typ == 'DNS' and val == hostname:
                return True
    else:
        return False

def pyopenssl_check_hostname(cert, hostname):
    ''' Return True if valid. False is invalid '''
    general_names = SubjectAltName()
    if cert.get_subject().commonName:
        for idx in range(0, cert.get_extension_count()):
            ext = cert.get_extension(idx)
            if ext.get_short_name() == "subjectAltName":
                san = ext.get_data()
                decoded_san = der_decoder.decode(san,asn1Spec=general_names)

                for name in decoded_san:
                    if isinstance(name, SubjectAltName):
                        for entry in range(len(name)):
                            component = name.getComponentByPosition(entry)
                            val = str(component.getComponent())
                            if component.getName() == 'dNSName' and val.startswith('*'):
                                # Wilcard
                                if val[2:] == hostname.split('.', 1)[1]:
#                                    print 'OK - wilcard'
                                    return True
                            # Normal hostnames
                            elif component.getName() == 'dNSName' and val == hostname:
#                                print 'OK - normal'
                                return True
    else:
        return False

def pyssl_check_expiration(cert):
    ''' Return the numbers of day before expiration. False if expired. '''
    if 'notAfter' in cert:
        try:
            expire_date = datetime.strptime(cert['notAfter'],
                                            "%b %d %H:%M:%S %Y %Z")
        except:
            #exit_error(1, 'Certificate date format unknow.')
            exit_error(1, '-0.982')

        expire_in = expire_date - datetime.now()
        if expire_in.days > 0:
            return expire_in.days
        else:
            return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('host', help='specify an host to connect to')
    parser.add_argument('-p', '--port', help='specify a port to connect to',
                        type=int, default=443)
    args = parser.parse_args()

    global HOST, PORT
    HOST = args.host
    PORT = args.port

    # Check the DNS name
    try:
        socket.getaddrinfo(HOST, PORT)[0][4][0]
    except socket.gaierror as e:
        exit_error(1, e)

    # Connect to the host and get the certificate
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))

    # If handled by python SSL library
    if not PYOPENSSL:
        try:
            ssl_sock = ssl.wrap_socket(sock, cert_reqs=ssl.CERT_REQUIRED,
                                       ca_certs=CA_CERTS,
                                       ciphers=("HIGH:-aNULL:-eNULL:"
                                                "-PSK:RC4-SHA:RC4-MD5"))

            cert = ssl_sock.getpeercert()
            if not pyssl_check_hostname(cert, HOST):
                #print 'Error: Hostname does not match!'
                print '-0.923'

            print pyssl_check_expiration(cert)

            sock = ssl_sock.unwrap()

        except ssl.SSLError as e:
            exit_error(1, e)

    # If handled by pyOpenSSL module
    else:
        try:
            ctx = SSL.Context(SSL.TLSv1_METHOD)
            ctx.set_verify(SSL.VERIFY_PEER | SSL.VERIFY_FAIL_IF_NO_PEER_CERT,
                           pyopenssl_check_callback)
            ctx.load_verify_locations(CA_CERTS)

            ssl_sock = SSL.Connection(ctx, sock)
            ssl_sock.set_connect_state()
            ssl_sock.set_tlsext_host_name(HOST)
            ssl_sock.do_handshake()

            x509 = ssl_sock.get_peer_certificate()
#            x509name = x509.get_subject()
#            if x509name.commonName != HOST:
#                print 'Error: Hostname does not match!'
#                print '-0.923'
            if not pyopenssl_check_hostname(x509, HOST):
                exit_error(1,'-0.923')

            ssl_sock.shutdown()

        except SSL.Error as e:
            exit_error(1, '-0.800')

    sock.close()


if __name__ == "__main__":
    main()

