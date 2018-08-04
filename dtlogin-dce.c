/*
 * DCE Authentication Integration for Solaris CDE login
 *
 * Paul Henson <henson@acm.org>
 *
 * Copyright (c) 1997 Paul Henson -- see COPYRIGHT file for details
 *
 */

#include <string.h>
#include <shadow.h>
#include <dce/sec_login.h>

/* Store the name of the user attempting to log in */
sec_rgy_name_t dce_username;

/* Flag whether or not to try a DCE login */
int dce_login = 0;


/* Prototype so compiler doesn't whine */
struct spwd *_getspnam(const char *name);


/* Override getspnam routine. If the request is for root, return the
 * real information from the local shadow file. Otherwise, return
 * fake information and set the flag to try a DCE login.
 */
struct spwd *getspnam(const char *name)
{
  static struct spwd s_pwd = { dce_username, "**dce**",
			       6445, -1, -1, -1, -1, -1, 0 };

  if (!strcmp(name, "root"))
    {
      dce_login = 0;
      return _getspnam(name);
    }
  else
    {
      dce_login = 1;
      strncpy(dce_username, name, sec_rgy_name_max_len);
      dce_username[sec_rgy_name_max_len] = '\0';
      return &s_pwd;
    }
}


/* Prototype so compiler doesn't whine */
char *_crypt(const char *key, const char *salt);


/* Override crypt routine. If we're not trying for a DCE login, return
 * the actual encrypted value for the given password. If we are going
 * for a DCE login, call the appropriate login API routines. If
 * everything works out, return a fake result to match the earlier fake
 * encrypted password from our getspnam function, so dtlogin's strcmp
 * will succeed. If something fails, return a bogus fake result that
 * doesn't match our fake encrypted password, so the strcmp fails.
 * Nifty, eh?
 */
char *crypt(const char *key, const char *salt)
{
  sec_login_handle_t login_context;
  sec_login_auth_src_t auth_src;
  sec_passwd_rec_t pw_entry;
  boolean32 reset_passwd;
  sec_passwd_str_t dce_pw;
  error_status_t dce_st;

  if (!dce_login)
    return _crypt(key, salt);

  dce_login = 0;
  
  if (!sec_login_setup_identity(dce_username, sec_login_no_flags, &login_context, &dce_st))
    return ("!failed!");

  pw_entry.version_number = sec_passwd_c_version_none;
  pw_entry.pepper = NULL;
  pw_entry.key.key_type = sec_passwd_plain;
  strncpy((char *)dce_pw, key, sec_passwd_str_max_len);
  dce_pw[sec_passwd_str_max_len] = '\0';
  pw_entry.key.tagged_union.plain = &(dce_pw[0]);

  if (!sec_login_valid_and_cert_ident(login_context, &pw_entry, &reset_passwd, &auth_src, &dce_st))
    {
      sec_login_purge_context(&login_context, &dce_st);
      return ("!failed!");
    }

  if (auth_src != sec_login_auth_src_network)
    {
      sec_login_purge_context(&login_context, &dce_st);
      return ("!failed!");
    }

  sec_login_set_context(login_context, &dce_st);

  if (dce_st)
    {
      sec_login_purge_context(&login_context, &dce_st);
      return ("!failed!");
    }

  return("**dce**");
}


