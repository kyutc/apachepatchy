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

Things to consider:
* https://imagetragick.com/
  * Specially crafted images processed by ImageMagick can result in RCE
* https://github.com/Balasys/dheater
  * Specially crafted requests on TLS results in a DoS
