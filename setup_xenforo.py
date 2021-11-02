import requests
from bs4 import BeautifulSoup

host = { 'Host': 'alfred.cpsc4270.local' }
session = requests.Session()
page = session.get('http://127.0.0.1/install/index.php?install/step/1', headers=host)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})

print(token['value'])

session.post('http://127.0.0.1/install/index.php?install/build-config', headers=host,
    data={
        'config[db][host]': 'localhost',
        'config[db][port]': '3306',
        'config[db][username]': 'xfusr',
        'config[db][password]': 'garlic',
        'config[db][dbname]': 'xfdb',
        'config[fullUnicode]': '1',
        '_xfToken': token['value']
    }
)

page = session.get('http://127.0.0.1/install/index.php?install/step/1b', headers=host)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})
print(token['value'])

page = session.post('http://127.0.0.1/install/index.php?install/step/2', headers=host,
    data={
        '_xfToken': token['value']
    }
)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})
print(token['value'])

page = session.post('http://127.0.0.1/install/index.php?install/step/2b', headers=host,
    data={
        '_xfToken': token['value']
    }
)

done = False
while not done:
    parser = BeautifulSoup(page.text, 'lxml')
    token = parser.find('input', {'name': '_xfToken'})
    print(token['value'])

    page = session.post('http://127.0.0.1/install/index.php?install/run-job', headers=host, allow_redirects=False,
        data={
            'execute': '1',
            '_xfRedirect': 'http://alfred.cpsc4270.local/install/index.php?install/step/3',
            '_xfToken': token['value']
        }
    )
    done = page.status_code == 303

page = session.get('http://127.0.0.1/install/index.php?install/step/3', headers=host)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})
print(token['value'])

page = session.post('http://127.0.0.1/install/index.php?install/step/3b', headers=host, allow_redirects=False,
    data={
        'username': 'Alfred',
        'password': 'knoblauch',
        'password_confirm': 'knoblauch',
        'email': 'alfred@localhost.localdomain',
        '_xfToken': token['value']
    }
)

page = session.get('http://127.0.0.1/install/index.php?install/step/4', headers=host)

parser = BeautifulSoup(page.text, 'lxml')
token = parser.find('input', {'name': '_xfToken'})
print(token['value'])

page = session.post('http://127.0.0.1/install/index.php?install/step/4b', headers=host, allow_redirects=False,
    data={
        'options[boardTitle]': 'XenForo',
        'options[boardUrl]': 'http://alfred.cpsc4270.local',
        'options[contactEmailAddress]': 'alfred@localhost.localdomain',
        'options[homePageUrl]': 'http://alfred.cpsc4270.local',
        'options[collectServerStats][configured]': '1',
        '_xfToken': token['value']
    }
)

page = session.get('http://127.0.0.1/install/index.php?install/complete', headers=host)
