import requests
from bs4 import BeautifulSoup

host = { 'Host': 'alfred.cpsc4270.local' }
session = requests.Session()
page = session.get('http://127.0.0.1/admin.php', headers=host)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})

print(token['value'])

page = session.post('http://127.0.0.1/admin.php?login/login', headers=host,
    data={
        'login': 'Alfred',
        'password': 'knoblauch',
        '_xfResponseType': 'json',
        '_xfToken': token['value']
    }
)

print(page.text)

# Create new user Abronsius
page = session.post('http://127.0.0.1/admin.php?users/0/save', headers=host,
    data={
        'user[username]': 'Abronsius',
        'user[email]': 'abronsius@localhost.localdomain',
        'password': 'knoblauch',
        'user[user_group_id]': '2',
        'user[secondary_group_ids]': '3',
        'user[user_state]': 'valid',
        'password': 'knoblauch',
        '_xfResponseType': 'json',
        '_xfToken': token['value']
    }
)

print(page.text)
