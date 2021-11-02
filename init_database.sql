create database if not exists xfdb;
create user if not exists 'xfusr'@'localhost' identified by 'garlic';
grant all on xfdb.* to 'xfusr'@'localhost';
