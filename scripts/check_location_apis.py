"""Exercise hosted location APIs with existing test accounts, without logging secrets."""
import json
import re
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
settings = (ROOT / 'lib/core/config/supabase_config.dart').read_text(encoding='utf-8')
base, public_key = re.findall(r"defaultValue: '([^']+)'", settings)
tests = dict(line.split('=', 1) for line in (ROOT / '.env.test.local').read_text(encoding='utf-8-sig').splitlines()
             if '=' in line and not line.lstrip().startswith('#'))


def request(path, body=None, token=None):
    headers = {'apikey': public_key, 'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(base + path, headers=headers,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        try:
            result = json.loads(error.read())
        except ValueError:
            result = {}
        return error.code, result


def login(role):
    status, data = request('/auth/v1/token?grant_type=password', {
        'email': tests['TEST_' + role + '_EMAIL'].strip(),
        'password': tests['TEST_ACCOUNT_PASSWORD'],
    })
    print(role + ' authentication HTTP ' + str(status))
    assert status == 200 and data.get('access_token'), role + ' test login failed'
    return data['access_token']


def report(label, status, data, expected=200):
    result = {'check': label, 'http': status}
    if isinstance(data, dict):
        if isinstance(data.get('erreur'), str):
            result['error'] = data['erreur']
        if isinstance(data.get('resultats'), list):
            result['result_count'] = len(data['resultats'])
        if isinstance(data.get('distance'), (float, int)):
            result['distance_m'] = data['distance']
            result['duration_s'] = data.get('duree')
            result['geometry_present'] = bool(data.get('geometrie'))
    print(json.dumps(result, ensure_ascii=True))
    assert status == expected, label + ' returned unexpected HTTP status'
    if expected == 200 and 'geocoding' in label:
        assert result.get('result_count', 0) > 0, 'Geocoding returned no results'
    if expected == 200 and 'route ' in label:
        assert result.get('distance_m', 0) > 0 and result.get('duration_s', 0) > 0 and result.get('geometry_present'), 'Route result incomplete'


status, data = request('/functions/v1/espaces-localisation', {'action': 'geocoder', 'recherche': 'Tunis'})
report('unauthenticated refusal', status, data, expected=401)
manager = login('MANAGER')
if manager:
    status, data = request('/functions/v1/espaces-localisation',
                           {'action': 'geocoder', 'recherche': 'Stade olympique de Rades'}, manager)
    report('manager public-place geocoding', status, data)
athlete = login('ATHLETE')
if athlete:
    status, data = request('/functions/v1/espaces-localisation',
                           {'action': 'geocoder', 'recherche': 'Tunis'}, athlete)
    report('athlete geocoding refusal', status, data, expected=403)
    status, spaces = request('/rest/v1/espace_sportif?select=id_espace&statut=eq.ACTIF&latitude=not.is.null&longitude=not.is.null&order=id_espace&limit=1', token=athlete)
    if status == 200 and spaces:
        for profile in ['foot-walking', 'cycling-regular', 'driving-car']:
            status, data = request('/functions/v1/espaces-localisation', {
                'action': 'itineraire', 'espace': spaces[0]['id_espace'],
                'depart': [10.18, 36.84], 'profil': profile,
            }, athlete)
            report('athlete route ' + profile, status, data)
    else:
        raise AssertionError('Route test blocked: no accessible destination with coordinates (HTTP ' + str(status) + ').')
