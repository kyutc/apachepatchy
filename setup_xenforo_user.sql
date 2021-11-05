update xf_user_authenticate
set scheme_class = 'XF:vBulletin',
data = 'a:2:{s:4:"hash";s:32:"c6ad2e96d763884eec60ab2434797610";s:4:"salt";s:30:"TR4lIoTcdcdglTz6c8xrDnATnJ5l3z";}'
where user_id = (select user_id from xf_user where username = 'Abronsius');
