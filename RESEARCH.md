Implemented attacks and information regarding them:
* Apache CVE-2021-41773
  * Description: Apache fails to consider that %2e in a URL will decode to "." and thus %2e%2e becomes ".." which allows traversing up directories from within the context of cgi-bin, and executing arbitrary files such as `/bin/sh`.
  * Mitigations:
    * Put Apache behind a proxy (such as NGINX) which pre-parses URLs
  * Solutions:
    * Update to latest version which fixes this CVE
    * Apply patch https://svn.apache.org/viewvc/httpd/httpd/branches/2.4.x/server/util.c?r1=1893775&r2=1893774&pathrev=1893775
    * Disable mod_cgi

* NGINX+php-fpm+UGC
  * Description: A misconfigured NGINX server with php-fpm can result in RCE due to passing a URL ending in .php of a non-existing file, but containing within it a file which does exist, which would then be executed by php-fpm as PHP code disregarding the remainder of the file path. For example: `/some.png/oops.php` would execute some.png as PHP code while disregarding the `/oops.php`. Images (or any other file) can easily contain valid code while still being valid images as well.
  * Mitigations:
    * Disallow direct access to UGC
    * Host UGC on a separate server dedicated for this content
    * Check uploaded files for indicators of code
  * Solutions:
    * Correct the configuration to validate that files exist before passing to php-fpm
    * Configure php-fpm to only execute files ending in .php
    * Use the latest version of php-fpm which by default will refuse to execute non-.php files.
    * Configure NGINX to only execute a static list of files

* vBulletin imported users
  * Description: Users which are imported from vBulletin will retain the weak password hash which vBulletin uses until the next time the user logs in, at which point the password hash will be updated to XenForo's far more secure format. A weak password hash will be far easier to crack, especially on a low budget.
  * Mitigations:
    * Require users to login to their accounts, especially staff, after an import
    * Educate users on password complexity and reuse
  * Solutions:
    * Do not import old user accounts; create these manually. (Too cumbersome to implement)
    * Encapsulate the old hash with a new, stronger hash. (This is not standard nor recommended by security professionals)
    * Assign each imported user a new temporary one-time-use password using the XenForo password hashing method, and require setting a new password upon login

  * Horizontal and Vertical Privilege Escalation
    * Description: Accessing another non-root user with sudo access allows transforming horizontal privilege escalation into vertical privilege escalation if their password becomes known. This is possible because the user abronsius was given far more access than it should have, in addition to the user hosting a vulnerable web server.
    * Mitigations:
      * Use setuid to run specified commands as other users/root. (Not recommended)
      * Limit sudo access to only the actions the specific user requires.
    * Solutions:
      * Do not install or use sudo.
      * Do not give sudo access to users running services such as HTTP.
      * Limit user accounts to one task; a user should not be running a web server while also being a personal access account.

  * Unencrypted Sensitive Data At Rest
    * Description: Database login information is contained in a file which could be read and expose the plaintext password.
    * Mitigations:
      * Set access permissions on `src/config.php` to 0400 to ensure only the www-data user has read access to it.
      * Run php-fpm as a separate user from NGINX so that NGINX cannot have read permission of the .php files.
      * Use an environment variable to pass the password to PHP. An attacker would require RCE as the php-fpm process to read it.
      * Encrypt the file. Cache the unencrypted file in memory only.
    * Solutions:
      * Solutions require code modifications to create alternate means of authentication and are therefore not practical in most cases.


### Technical details for vBulletin imported users
Before the user logs into a newly-imported account, the database will look like this:
```
MariaDB [xfdb]> select * from xf_user_authenticate;
+---------+--------------+------------------------------------------------------------------------------------------------------------+
| user_id | scheme_class | data                                                                                                       |
+---------+--------------+------------------------------------------------------------------------------------------------------------+
|       1 | XF:Core12    | a:1:{s:4:"hash";s:60:"$2y$10$ylne2nP3XtLUcPGKS0raNukoUWiuJ69/wRoMHEuyH6rfQgm3KlytG";}                      |
|       3 | XF:vBulletin | a:2:{s:4:"hash";s:32:"c6ad2e96d763884eec60ab2434797610";s:4:"salt";s:30:"TR4lIoTcdcdglTz6c8xrDnATnJ5l3z";} |
+---------+--------------+------------------------------------------------------------------------------------------------------------+
```
Note the scheme_class of XF:vBulletin for user_id 3. After the user logs in, the database will be updated to hash their password using the newer, better scheme:
```
MariaDB [xfdb]> select * from xf_user_authenticate;
+---------+--------------+---------------------------------------------------------------------------------------+
| user_id | scheme_class | data                                                                                  |
+---------+--------------+---------------------------------------------------------------------------------------+
|       1 | XF:Core12    | a:1:{s:4:"hash";s:60:"$2y$10$ylne2nP3XtLUcPGKS0raNukoUWiuJ69/wRoMHEuyH6rfQgm3KlytG";} |
|       3 | XF:Core12    | a:1:{s:4:"hash";s:60:"$2y$10$uFrrxiZRkoxip8z9UbWlDOLvp0uv/bqhXfy4IP8M1WNUHcEKLaEgy";} |
+---------+--------------+---------------------------------------------------------------------------------------+
```
Note that user_id 3's scheme_class has now changed, and the underlying data is in the new format as well. If the account is never logged into, the password hash will remain as the old and much weaker method. This better method makes use of bcrypt and is far more resource-intensive to attempt cracking. More information: https://www.php.net/manual/en/function.password-hash.php

### Hash cracking details for vBulletin imported users
Because vBulletin uses a particularly weak method for password hashing consisting of md5(md5(password).salt), it is fairly easy to crack passwords on relatively cheap hardware. In this demo, I cracked a 9 character lowercase alphabetical password via brute force on a GTX 1080 in about 2 minutes.

Hashcat can be used with GPU acceleration to crack the password like so:
```sh
hashcat -a 3 -m 2611 hashes.txt ?l?l?l?l?l?l?l?l?l
```
The option `-a 3` instructs hashcat to perform a brute force attack, which is not ideal under most circumstances but is viable against the weak hashing method vBulletin uses. This means checking every input from aaaaaaaaa, aaaaaaaab, ..., through zzzzzzzzz. `-m 2611` selects the hashing method to use which coincides with vBulletin, that being `md5(md5(password).salt)`. `hashes.txt` is the input file which contains a list of hashes to crack in the format of `hash:salt`. The final option `?l?l?l?l?l?l?l?l?l` is the mask used which means 9 lowercase alphabetical characters.

Output:
```
c6ad2e96d763884eec60ab2434797610:TR4lIoTcdcdglTz6c8xrDnATnJ5l3z:knoblauch

Session..........: hashcat
Status...........: Cracked
Hash.Mode........: 2611 (vBulletin < v3.8.5)
Hash.Target......: c6ad2e96d763884eec60ab2434797610:TR4lIoTcdcdglTz6c8...nJ5l3z
Time.Started.....: Fri Nov  5 14:27:19 2021 (2 mins, 7 secs)
Time.Estimated...: Fri Nov  5 14:29:26 2021 (0 secs)
Kernel.Feature...: Pure Kernel
Guess.Mask.......: ?l?l?l?l?l?l?l?l?l [9]
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:  2173.9 MH/s (9.16ms) @ Accel:64 Loops:64 Thr:256 Vec:1
Recovered........: 1/1 (100.00%) Digests
Progress.........: 277641953280/5429503678976 (5.11%)
Rejected.........: 0/277641953280 (0.00%)
Restore.Point....: 15728640/308915776 (5.09%)
Restore.Sub.#1...: Salt:0 Amplifier:3584-3648 Iteration:0-64
Candidate.Engine.: Device Generator
Candidates.#1....: zztpyvcta -> jlluopevi
Hardware.Mon.#1..: Temp: 73c Fan: 59% Util:100% Core:1923MHz Mem:5005MHz Bus:16

Started: Fri Nov  5 14:27:17 2021
Stopped: Fri Nov  5 14:29:27 2021
```

Things to consider:
* https://imagetragick.com/
  * Specially crafted images processed by ImageMagick can result in RCE
* https://github.com/Balasys/dheater
  * Specially crafted requests on TLS results in a DoS
